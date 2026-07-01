---
title: nana-harness — Interface Design Brief
type: reference
updated: 2026-07-01
grounded_as_of: Phase 119 (persistent Pi session + felt-quality + ecosystem slice)
grounding: parallel ground-read of app/src/ui/**, app/src/{engine/pi,host,gate,context,control}/**, app/src-tauri/**, app/src/styles.css
related: [[pi-ux-persistent-session-slice]], [[pi-gate-survives-mutation]], [[engine-adapter-in-process-gate]], [[axis3-command-palette]], [[conversation-memory-persistence]]
---

# nana-harness — Interface Design Brief

> Grounded reference, not a decision record. Describes the shipped UI as of Phase 119.
> Re-ground before trusting after any UI-layer phase (Ph120+).

## 1. Surface at a glance
One native window (`dev.nana.harness`, 1280×832, "Nana Dev-Harness") as a flex column: fixed header, flexible body, fixed composer. The body is a CSS grid `.surface` — `1fr` chat + a `300px` side panel — with the context/cost meter as a full-width footer (`grid-column:1/-1`). Header carries a right-aligned engine-status pill ("engine connected / offline / connecting…") and a workspace chip (basename, `40ch` ellipsis, full-path tooltip). Two overlays live `position:absolute; inset:0`, scrimmed `rgba(8,9,12,0.6)`, layered by z-index: the gate-confirm modal (z=10) and the Cmd+K palette (z=20). Side panel stacks "Recent edits" (revert controls) over "Artifacts" (typed tool outputs).

## 2. Chat / conversation model
Unstyled assistant-ui primitives over an external-store runtime that folds **one engine-neutral `UiMessage` stream** — the reduction never learns which engine it's rendering (Pi, Vercel-AI-SDK, or Claude render identically). Composer placeholder "Message the harness…"; the action button mode-swaps blue **Send** (idle) ↔ red **Stop** (running, interrupts in-flight). Running shows an amber `aria-live` banner: "working… (local models are slow — this can take a few minutes)" with a pulsing dot. Streaming is driven by **clone-on-commit** — `applyEngineEvent` mutates in place, so `commitEvent` rebuilds array/message/toolCalls identities or React wouldn't re-render. Turn failures surface as visible text ("⚠ Turn failed: …"), never a silent bubble.

Persistence is per-workspace (`nana.conv.v1:<root>` in localStorage), redacted at the disk boundary (write bodies → "«write content omitted: N bytes»"), fail-soft (quota/parse failures degrade to `[]`, 256KB backstop, 400-message cap). **Restore is display-only**: it sets the store without touching engine or gate, so a restored thread raises a `role=status` marker — "restored — model context reset (the model does not remember them)" — to kill the false-memory illusion.

## 3. Human-in-the-loop gate & artifacts
A destructive tool call parks as an unresolved `Promise<GateDecision>` the adapter is already awaiting — **blocking needs no new mechanism**. The confirm overlay is a modal `alertdialog`: "gate hold" badge + tool name + human-readable reason + colorized diff, with **Deny** / **Approve & run**. Multiple holds queue with a pending count. The escalation boundary is a literal-phrase match — only reasons containing "requires explicit human confirmation" can become approvable; hard denials (secret/keystore) never can. Approve → action lands + `CheckpointStore.snapshot()` (records absence too, so a created file can be un-created); Deny → hard "rejected by human". Approved edits append to "Recent edits" as one-click `RevertControl` buttons that rewind to exact pre-action bytes (deletes soft-trashed). A gate denial renders inline as a distinct "blocked by gate: `<reason>`" chip — security UX is always visible, never dropped.

## 4. Felt-quality controls
Meter footer: `120×5px` progress fill (`0.3s` transition) + "42%" + "12.3k / 262k" tokens + right-pushed amber "$0.00" cost; renders "—" not "NaN%" in the post-compaction window. Two mono chips (button when clickable, inert span otherwise): "model: `<label>`" (appends " · local" for the $0 provider) and "thinking: `<level>`" (inert "off" with tooltip when the model can't think). **Cmd+K** is hand-rolled (no `cmdk` dep — ~6 static commands don't justify it), `12vh` top-aligned, filter-by-title/keyword, arrow-nav, Enter-run, Esc/backdrop-close. Commands: Stop, Deny, Revert last, New conversation (Cmd+N), Focus composer, Compact, Cycle model, Cycle thinking, Change workspace. **Approve is deliberately excluded from the palette** — the only keyboard approve is Cmd/Ctrl+Enter, so a reflexive Cmd+K-then-Enter can never approve a destructive call. Slash-commands append dynamically: a template submits its content, a skill submits `Use the "<name>" skill.` — both through the gated prompt path.

## 5. Native shell's contribution
A deliberately thin Tauri v2 Rust host owns real window chrome (default decorations, **no transparency** — "honest native chrome") and exactly four invoke commands. The webview capability manifest is `core:default` only (**no fs/shell/http/dialog**) under a sealed CSP (`default-src 'self'`, `object-src 'none'`, `frame-ancestors 'none'`) — privilege starts empty. The Node engine-host runs as a Rust-spawned sidecar relayed line-by-line. The folder picker runs **in Rust** (the chosen folder *is* the gate's free-write zone); a workspace change kills+reaps the old sidecar and re-spawns with a fresh gate. API keys live in the OS keychain; the renderer never handles a raw key.

## 6. Visual language
Single-file, dark-only "control-instrument console" from one `:root` token block. Four slate tiers (`--bg-0 #0f1115` → `--bg-3 #262b3d`) with `--line #2c3242` for instrument-panel layering (slate, not flat black). Dual typeface: `--mono` for structure/labels/tool-output/meter, `--sans` for prose (system fonts only). Traffic-light vocabulary each with a dim companion — `--go #4ade80`, `--warn #fbbf24`, `--stop #f87171` — plus `--accent #7aa2f7` (Tokyo-Night periwinkle) for interactive/brand. Overlays color-code by top-border: gate modal `3px --warn`, palette `3px --accent`. Geometry `--r 8px` / `999px` pills; base `14px/1.5`, micro-labels `10–11px` uppercase, `0.08–0.12em` tracking.

## 7. The load-bearing invariant
**Every action re-dispatches an existing gated path — no new privileged surface.** Composer, palette templates, and slash-skills all funnel through `runPrompt → engine.sendPrompt → the host gate`. The gate runs host-side (`BridgeClient.setToolCallGate` is a deliberate no-op — the webview is pure transport), installed once in the session ctor; none of setModel/cycleModel/compact/setThinking reassign it, so it **survives the persistent single session and every felt-quality mutation** ([[pi-gate-survives-mutation]]). Change-workspace re-spawns a fresh gate; restore never touches the engine. The security boundary is structural, not promised.

---

## How it compares to Claude Code

Not the same category. Claude Code is a broad, mature, **Claude-first, multi-surface** harness; nana is a narrow, **owned, GUI-primary, model-agnostic** desktop harness whose spine is a single un-bypassable gate. The comparison that matters is by kind, not feature count.

| Dimension | nana-harness | Claude Code |
|---|---|---|
| **Form factor** | One native Tauri desktop window; GUI-primary; tool calls/diffs/meter/chips as **visual** affordances | Terminal-TUI primary, but multi-surface: CLI, desktop (Mac/Win), web, IDE (VS Code/JetBrains). Text-first |
| **Model** | **Model-agnostic** — embeds Pi SDK, cycles engines, **local $0 default**; meter reads `$0.00` | Claude-only (Opus/Sonnet/Haiku/Fable); `/model` + fast mode; no local path |
| **Security boundary** | **Single un-bypassable in-process gate** — call parks as an awaited Promise; no bypass mode exists; gate structurally survives persistence + every mutation | Permission system + hooks: modes (default/acceptEdits/plan/**bypassPermissions**), allowlists, `PreToolUse` block-with-exit-2. Richer & more configurable — but a policy *layer* with an explicit bypass escape hatch |
| **Approval UX** | Modal `alertdialog` + colorized diff + Approve/Deny; literal-phrase escalation; deny = hard reject | Inline terminal/IDE diff + allow/deny prompt; per-tool/per-path rules |
| **Undo** | One-click per-edit `RevertControl` → exact pre-action bytes; soft-trash deletes | `/rewind` + checkpoints (Esc-Esc) + git; session-level, not per-artifact-strip |
| **Command surface** | **Visual Cmd+K palette** + composer slash-commands + shortcuts | Slash-commands typed in composer + shortcuts; no visual palette (TUI) |
| **Resume semantics** | **Display-only** restore + honest "model context reset" marker (engine session is fresh) | `--resume`/`--continue` restores **actual model context** — the conversation genuinely continues |
| **Compaction** | Manual `/compact` (added Ph119) | `/compact` + auto/micro-compaction — more mature |
| **Ecosystem** | Embedded MCP memory server (host-orchestrated), skills-via-palette, gate plays the hook role — thin, single-surface | MCP, hooks, skills, plugins, subagents, workflows, worktrees, background/remote tasks, cron — deep and broad |
| **Ownership** | Maintainer owns the whole stack (Rust shell + Node host + adapters + gate) in one auditable repo; privilege starts empty | First-party Anthropic product — you configure it, you don't own the call site |

**Where nana differs in kind (not just "less"):**
- The gate is **structurally** un-bypassable — no `bypassPermissions` equivalent. That was the entire reason to embed Pi in-process rather than adopt ACP/opencode/Goose (couldn't own the call site).
- **Model agnosticism with a $0 local default** — a category Claude Code doesn't play in.
- **Honest restore** — nana refuses to fake continuity; Claude Code actually delivers continuity. Opposite bets, both defensible.
- A **visual Cmd+K palette** as a first-class surface, which a terminal harness structurally can't offer the same way.

**Where Claude Code is clearly ahead:** maturity (compaction, true resume, breadth), multi-surface reach, configurability, and it's a shipping product with an ecosystem — not a Phase-119 dogfood slice.

**The actual bet:** nana trades Claude Code's breadth and configurability for a boundary that's *structurally impossible to bypass* and a UI where the security state is always visible. For a daily-driver that touches the filesystem, a minimal provable gate with no escape hatch beats a richer permission layer that has one. That is the cost-of-error trade nana is built around — model-agnostic + GUI-native felt-quality ride on top of that spine.
