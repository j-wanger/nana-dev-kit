#!/usr/bin/env python3
"""Register hooks and MCP servers in Claude Code settings.json.

Usage:
  register-settings.py hooks <settings.json> <modules.json> [--scope global|project-local] [--hooks-dir <dir>] [--dry-run]
  register-settings.py mcp <settings.json> --python <path> --cwd <dir> [--dry-run]
"""

import argparse
import json
import os
import sys


def upsert_hook(hooks, event, matcher, hook_file, hooks_dir, hook_type="command"):
    path = os.path.join(hooks_dir, hook_file)
    key = "prompt" if hook_type == "prompt" else "command"
    if event not in hooks:
        hooks[event] = []
    for e in hooks[event]:
        for inner in e.get("hooks", []):
            if inner.get(key, "").endswith(hook_file):
                if matcher and e.get("matcher") != matcher:
                    e["matcher"] = matcher
                elif not matcher and "matcher" in e:
                    del e["matcher"]
                return
    for e in hooks[event]:
        if e.get(key, "").endswith(hook_file) and "hooks" not in e:
            keep_matcher = e.get("matcher")
            e.clear()
            if keep_matcher:
                e["matcher"] = keep_matcher
            e["hooks"] = [{"type": hook_type, key: path}]
            return
    entry = {}
    if matcher:
        entry["matcher"] = matcher
    entry["hooks"] = [{"type": hook_type, key: path}]
    hooks[event].append(entry)


def remove_ghost(hooks, ghost_name):
    for event in list(hooks.keys()):
        hooks[event] = [
            e for e in hooks[event]
            if not any(ghost_name in h.get("command", "") for h in e.get("hooks", []))
        ]


def _entry_basename(entry):
    """The script basename this registration entry points at (first inner command/prompt)."""
    for inner in entry.get("hooks", []):
        cmd = inner.get("command") or inner.get("prompt") or ""
        if cmd:
            return cmd.rsplit("/", 1)[-1]
    return ""


def _is_canonical(entry):
    """True if the entry uses the ${CLAUDE_PROJECT_DIR}-prefixed (CWD-robust) command form."""
    for inner in entry.get("hooks", []):
        if "${CLAUDE_PROJECT_DIR}" in (inner.get("command") or inner.get("prompt") or ""):
            return True
    return False


def dedupe_by_basename(hooks):
    """Collapse registrations sharing a script basename within an event, keeping ONE.

    DRQ-1 (verified 2026-06-10): Claude Code dedupes hook registrations only when the command
    STRINGS are byte-identical; two distinct strings invoking the same script (e.g. a bare
    relative path AND a ${CLAUDE_PROJECT_DIR}-absolute one, the Phase-79 hand-patch class) BOTH
    fire. upsert_hook matches by endswith and cannot remove the other copy, so this normalizes
    by basename. The ${CLAUDE_PROJECT_DIR}-prefixed (canonical, CWD-robust) survivor is preferred.

    Granularity: keyed by basename WITHIN an event (aggressive) — it collapses the same script
    registered twice in one event regardless of matcher. No kit hook registers one script under
    two matchers in a single event, so this is safe for the kit; a consumer that legitimately
    wires one script to two matchers in one event would lose one (the dry-run-first live
    follow-on surfaces that before applying). The alternative — keying by (basename, matcher) —
    would instead leave a matcher-mismatched Phase-79 duplicate uncollapsed; aggressive wins here.
    """
    for event in list(hooks.keys()):
        seen = {}   # basename -> index in `kept`
        kept = []
        for e in hooks[event]:
            bn = _entry_basename(e)
            if not bn:
                kept.append(e)
                continue
            if bn in seen:
                idx = seen[bn]
                if _is_canonical(e) and not _is_canonical(kept[idx]):
                    kept[idx] = e   # prefer the canonical form; drop the other
                # else: drop this duplicate
            else:
                seen[bn] = len(kept)
                kept.append(e)
        hooks[event] = kept


def cmd_hooks(args):
    with open(args.modules_json) as f:
        manifest = json.load(f)

    # Single canonical scope-tagged hook list. Filter by requested scope:
    # project-local install (and the generated per-project template) gets
    # scope=="project" hooks; global install gets scope=="global" hooks.
    all_hooks = manifest.get("hooks", [])
    if args.scope == "project-local":
        hook_defs = [h for h in all_hooks if h.get("scope") == "project"]
        # ${CLAUDE_PROJECT_DIR} (set + expanded by Claude Code before execution) makes the registered
        # command resolve regardless of the CWD Claude Code runs the hook from — bare relative paths
        # 404 under CWD-drift (Phase 79). The file COPY still targets the relative .claude/hooks; only
        # the registered command path is absolutized here.
        hooks_dir = args.hooks_dir or "${CLAUDE_PROJECT_DIR}/.claude/hooks"
        ghosts = []
    else:
        hook_defs = [h for h in all_hooks if h.get("scope") == "global"]
        hooks_dir = args.hooks_dir or os.path.expanduser("~/.claude/hooks")
        ghosts = manifest.get("ghost_cleanup", [])

    if args.dry_run:
        for h in hook_defs:
            print(f"[dry-run] register {h['event']}:{h.get('matcher', '')} -> {h['script']}")
        for g in ghosts:
            print(f"[dry-run] remove ghost: {g}")
        return

    settings_path = args.settings_json
    data = {}
    if os.path.isfile(settings_path):
        with open(settings_path) as f:
            data = json.load(f)
    if "hooks" not in data or args.regenerate:
        data["hooks"] = {}
    hooks = data["hooks"]

    for h in hook_defs:
        upsert_hook(hooks, h["event"], h.get("matcher", ""), h["script"], hooks_dir,
                     hook_type=h.get("type", "command"))

    for g in ghosts:
        remove_ghost(hooks, g)

    if getattr(args, "dedupe", False):
        dedupe_by_basename(hooks)

    with open(settings_path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def cmd_deregister(args):
    """Remove every hook registration whose command basename matches a --basename target.

    Basename-normalized (DRQ-1): a cut hook may be registered under several distinct command
    strings; all are removed. This is the deregistration mechanism the kit never shipped
    (register-settings was upsert-only — [[prune-on-value-subtraction]]); it is destructive, so
    install.sh gates it behind a timestamped backup + survivor smoke + revert-on-failure.
    """
    targets = set(args.basename or [])
    settings_path = args.settings_json
    if not targets or not os.path.isfile(settings_path):
        return
    with open(settings_path) as f:
        data = json.load(f)
    hooks = data.get("hooks", {})

    if args.dry_run:
        for event in hooks:
            for e in hooks[event]:
                if _entry_basename(e) in targets:
                    print(f"[dry-run] deregister {event}: {_entry_basename(e)}")
        return

    for event in list(hooks.keys()):
        hooks[event] = [e for e in hooks[event] if _entry_basename(e) not in targets]

    with open(settings_path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def cmd_mcp(args):
    # Server name + module come from modules.json when provided (Phase 82) — they were
    # hardcoded here, which made the manifest's declared mcp block dead config.
    name, module, env = "memory", "memory_server", None
    if getattr(args, "modules_json", None) and os.path.isfile(args.modules_json):
        with open(args.modules_json) as f:
            manifest = json.load(f)
        for m in manifest.get("modules", []):
            mcp = m.get("mcp")
            if mcp:
                name = mcp.get("name", name)
                module = mcp.get("module", module)
                env = mcp.get("env")  # optional {VAR: value}; values may contain ~ or $HOME
                break

    if args.dry_run:
        print(f"[dry-run] register MCP: name={name}, module={module}, python={args.python}, cwd={args.cwd}, env={env}")
        return

    settings_path = args.settings_json
    data = {}
    if os.path.isfile(settings_path):
        with open(settings_path) as f:
            data = json.load(f)
    if "mcpServers" not in data:
        data["mcpServers"] = {}
    entry = {
        "command": os.path.expanduser(args.python),
        "args": ["-m", module],
        "cwd": os.path.expanduser(args.cwd),
    }
    if env:
        # cwd is CLI-passed; env is manifest-sourced (deliberate sourcing asymmetry — Phase 91).
        # Expand $HOME and ~ in env values so a relative kit path resolves at registration time.
        entry["env"] = {k: os.path.expanduser(os.path.expandvars(str(v))) for k, v in env.items()}
    data["mcpServers"][name] = entry

    with open(settings_path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def main():
    parser = argparse.ArgumentParser(description="Register hooks and MCP servers in settings.json")
    sub = parser.add_subparsers(dest="command")

    p_hooks = sub.add_parser("hooks", help="Register hooks from modules.json")
    p_hooks.add_argument("settings_json", help="Path to settings.json")
    p_hooks.add_argument("modules_json", help="Path to modules.json")
    p_hooks.add_argument("--scope", choices=["global", "project-local"], default="global")
    p_hooks.add_argument("--hooks-dir", help="Override hooks directory path")
    p_hooks.add_argument("--regenerate", action="store_true",
                         help="Clear the hooks block and rebuild from scratch (deterministic template generation)")
    p_hooks.add_argument("--dedupe", action="store_true",
                         help="Collapse duplicate registrations sharing a script basename (DRQ-1)")
    p_hooks.add_argument("--dry-run", action="store_true")

    p_dereg = sub.add_parser("deregister", help="Remove registrations by script basename (DRQ-1)")
    p_dereg.add_argument("settings_json", help="Path to settings.json")
    p_dereg.add_argument("--basename", action="append", default=[],
                         help="Script basename to deregister (repeatable), e.g. detect-loop.sh")
    p_dereg.add_argument("--dry-run", action="store_true")

    p_mcp = sub.add_parser("mcp", help="Register MCP memory server")
    p_mcp.add_argument("settings_json", help="Path to settings.json")
    p_mcp.add_argument("--python", required=True, help="Path to Python interpreter")
    p_mcp.add_argument("--cwd", required=True, help="Working directory for MCP server")
    p_mcp.add_argument("--modules-json", help="modules.json path; mcp server name/module read from its mcp block")
    p_mcp.add_argument("--dry-run", action="store_true")

    args = parser.parse_args()
    if args.command == "hooks":
        cmd_hooks(args)
    elif args.command == "deregister":
        cmd_deregister(args)
    elif args.command == "mcp":
        cmd_mcp(args)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
