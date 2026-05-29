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


def cmd_hooks(args):
    with open(args.modules_json) as f:
        manifest = json.load(f)

    # Single canonical scope-tagged hook list. Filter by requested scope:
    # project-local install (and the generated per-project template) gets
    # scope=="project" hooks; global install gets scope=="global" hooks.
    all_hooks = manifest.get("hooks", [])
    if args.scope == "project-local":
        hook_defs = [h for h in all_hooks if h.get("scope") == "project"]
        hooks_dir = args.hooks_dir or ".claude/hooks"
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

    with open(settings_path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def cmd_mcp(args):
    if args.dry_run:
        print(f"[dry-run] register MCP: python={args.python}, cwd={args.cwd}")
        return

    settings_path = args.settings_json
    data = {}
    if os.path.isfile(settings_path):
        with open(settings_path) as f:
            data = json.load(f)
    if "mcpServers" not in data:
        data["mcpServers"] = {}
    data["mcpServers"]["memory"] = {
        "command": os.path.expanduser(args.python),
        "args": ["-m", "memory_server"],
        "cwd": os.path.expanduser(args.cwd),
    }

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
    p_hooks.add_argument("--dry-run", action="store_true")

    p_mcp = sub.add_parser("mcp", help="Register MCP memory server")
    p_mcp.add_argument("settings_json", help="Path to settings.json")
    p_mcp.add_argument("--python", required=True, help="Path to Python interpreter")
    p_mcp.add_argument("--cwd", required=True, help="Working directory for MCP server")
    p_mcp.add_argument("--dry-run", action="store_true")

    args = parser.parse_args()
    if args.command == "hooks":
        cmd_hooks(args)
    elif args.command == "mcp":
        cmd_mcp(args)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
