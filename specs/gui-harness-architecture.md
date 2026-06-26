<!-- nana:approved 2026-06-26 (direct /spec: clean-context adversarial-constraint pass + Tier-1 review 7/10→revised + primary-source verification of the engine/security claims) -->
# Spec: GUI Dev-Harness Architecture (nana-dev-kit pivot)

<!-- Rev 2 (2026-06-26): engine/boundary reversed after primary-source verification — the security gate must live IN-PROCESS at the tool call site; ACP/opencode-HTTP/Goose/Paseo cannot own it. Engine = embedded Pi SDK (gate via tool_call hook), Claude Agent SDK as neutrality-proving 2nd adapter. -->

## Objective

Re-platform nana-dev-kit from a Claude Code terminal skill-pack into a **GUI-primary, model-agnostic desktop dev harness** that becomes the maintainer's primary daily interface for agentic software engineering. The harness **owns its surface** (the joy/sense-of-control north star), **embeds a model-agnostic agent engine in-process behind an adapter interface the app owns**, and preserves the existing memory + lifecycle assets that re-platforming permits.

## Context

nana-dev-kit today is a Claude Code extension pack: skills (markdown prompts), hooks (shell scripts on settings.json lifecycle events, some blocking via exit-code 2), an MCP stdio memory server (Python), and markdown project-state / dev-wiki / spec files the CLI auto-loads. The maintainer is a solo developer (AML / financial-crime domain); this is the daily driver. The decision (2026-06-26) is to move OFF the terminal CLI onto a standalone desktop GUI the maintainer builds and owns, because the felt experience — joy and a strong sense of control — is the variable that matters and is the maintainer's to judge directly (the UI-quality carve-out: human-facing UI quality is unmeasurable in-kit and ships on stated need + judgment).

A mid-2026 landscape survey established that no existing tool is simultaneously GUI-primary, claude.ai-polished, a real dev harness, and cleanly forkable — so the strategy is *build the surface, adopt the engine*. A subsequent architecture review plus primary-source verification then established the load-bearing constraint that shapes this contract: **the security gate (deny/modify a destructive tool call before it runs) can only be owned by the host if the agent loop runs in the host's own process.** Verified against primary sources (mid-2026): the Agent Client Protocol's permission request is the agent's discretion ("MAY", no enforcement; agents run as local subprocesses and may do file/shell I/O entirely outside the protocol — the pi-acp adapter does exactly this); and opencode's HTTP server, Goose's daemon, and Paseo's supervisor each run the agent in *their* process and merely relay the agent's own permission prompts. None lets the host own a pre-execution gate. Therefore the "adopt the engine" strategy is realized by **embedding an agent SDK in-process**, not by driving a server or speaking a wire protocol. This contract is the architecture decision record; it precedes `/dev-plan` and is not a task list.

## Scope

### In scope
- **The architecture decisions** (shell, surface, in-process engine, the engine-adapter interface, the in-process security gate, provider routing, language seams) — RESOLVED here with justification + fallback.
- **The seam contracts:** an internal engine-adapter interface the app owns (≥2 implementations); MCP stdio for memory/tools; the engine's own event stream (assistant-ui's AI-SDK-shaped runtime) for the UI.
- **The porting matrix:** what survives as-is, what is rebuilt as app code (including where the kit's exit-code-2 blocking gates re-home), what converts manually.
- **The desktop-agent security model:** key custody, tool-output rendering, the in-process pre-execution gate, mutation reversibility, spend ceilings, capability-manifest audit.
- **The v1 thin-slice acceptance bar** (the minimum daily loop that proves the architecture, gate included).

### Out of scope
- The task breakdown / phase plan — that is `/dev-plan`, run after this contract is approved.
- Full implementation of any subsystem — this defines seams + the first slice.
- Porting every CLI feature 1:1 — port-on-demand; only the minimum daily loop is v1.
- Rewriting the Python MCP memory server — it ports as-is via MCP stdio.
- **Relying on a wire protocol (ACP) or an external agent process (opencode-HTTP / Goose / Paseo) for the security gate** — verified incapable of guaranteed pre-execution interception; disqualified as the security spine.
- Forking Paseo (AGPL-3.0, supervisor/relay architecture) as the base — study it as a UX reference only.
- New gate semantics / eval scenarios for the current terminal kit; multi-user / hosted / cloud-sync (local-first, single-user).

## Approach

**Boundary-first principle (the invariant):** the security gate is the load-bearing invariant, and it can only live **in-process at the engine's tool-dispatch site**. So the "swappable boundary" is an **internal engine-adapter interface the app owns** — not someone's wire protocol. The engine is embedded; the gate wraps its tool dispatch; swapping engines is a new adapter implementation behind a fixed internal interface.

Decisions, each with justification + fallback + first-slice validation:

- **Shell — Tauri** (Rust core + system webview): native feel, small footprint, and a capability-scoped webview with enforceable CSP. Two verified corrections: OS-keychain access is via the **`keyring-rs` Rust crate**, *not* a first-party Tauri plugin (Stronghold is deprecated); and the **Tauri capability manifest is the real security boundary** — an over-broad filesystem/shell capability chained with an XSS is RCE, so the manifest is audited, not defaulted. Web build = dev-iteration only.
- **Surface — assistant-ui** (custom runtime pointed at the engine adapter) + **Vercel AI Elements'** dev components (Terminal, FileTree, TestResults, diff/CodeBlock). shadcn/React, owned not adopted. **AG-UI is dropped** — assistant-ui rides the Vercel AI-SDK data-stream, so AG-UI's event taxonomy is redundant here.
- **Engine — embed Pi's coding-agent SDK in-process** (`@earendil-works/pi-coding-agent`, MIT, TS, model-agnostic across 25+ providers via `pi-ai`). This is the reversal of Rev 1's opencode pick. Pi gives you the agent loop AND the gate, so you neither build the loop (the rejected option) nor forfeit the gate (the disqualifying flaw of server/protocol engines). The host owns a pre-execution gate via Pi's **`tool_call` extension hook**: `return { block: true, reason }` denies; mutating `event.input` modifies arguments; it covers built-in (read/write/edit/bash) and custom tools and runs in the host-registered extension, in-process. (Verified mechanism — note: Pi does *not* permit replacing built-in tool implementations; the gate is the dispatch-site hook, not tool wrapping, and the post-hoc `tool_execution_*` event stream is too late to gate.)
- **Engine — second adapter: Claude Agent SDK** (`canUseTool` → allow / deny / `updatedInput`, pre-execution, vendor-supported). Built in the first slice alongside Pi to **prove the internal gate abstraction is engine-neutral**, and as the Claude-fidelity path. Anthropic-only, so an adapter behind the model-agnostic interface, never the backbone. **Deeper fallback: Vercel AI SDK** (build the loop, own the tool dispatch directly) if Pi's open-core/0.x churn becomes untenable.
- **External agents — optional, fenced:** ACP / opencode / Goose remain an optional "**import an external agent**" feature (drive Codex/Gemini/Claude Code/opencode as a subprocess). Anything driven this way **runs outside the host gate** (cooperative permission only) and is used solely in trusted or sandboxed contexts — never as the security spine.
- **Provider routing — Pi's `pi-ai` layer** (25+ providers, mid-session switch). LiteLLM/OpenRouter added only if a needed provider is missing; pin versions (LiteLLM Mar-2026 supply-chain incident).
- **Language seams — polyglot, joined by interfaces:** a TS/React surface + a Rust (Tauri) shell + the **Pi SDK embedded in the app's TS/Node layer** + the existing Python MCP memory server mounted via MCP stdio (unchanged — MCP is the seam).

The "adopt the engine, don't build the loop, own the GUI" strategy is unchanged from the locked direction — Pi *is* the adopted engine (its loop + unified LLM API). Only the integration mode moved from "drive a server/protocol" to "embed the SDK in-process," which is precisely what makes the security gate ownable.

### Porting matrix

| Asset | Disposition | Notes |
|---|---|---|
| MCP memory server (Python) | **Survives as-is** | Mounted via MCP stdio; not rewritten. The spine. |
| dev-wiki / spec / project-state markdown | **Survives as-is** | Pure data; read by the app's context-assembly layer. |
| AGENTS.md | **Survives as-is** | Cross-tool standard; emitted/consumed for per-project instructions. |
| Context loader (`.claude/rules/*` auto-load, SessionStart injection) | **Rebuilt as app code** | The app's context-assembly layer — what gets loaded into each turn. |
| Blocking lifecycle hooks (`enforce-*`, exit-code-2 gates) | **Rebuilt as app code** | Re-home into the **in-process pre-execution gate** — Pi's `tool_call` hook (or Claude SDK `canUseTool`) at the engine's tool-dispatch site. The host registers it; the model has no channel to deregister it. This is the kit's safety spine and is the reason the engine must be in-process. |
| Advisory hooks (`audit-log`, `scope-check`) | **Rebuilt as app code** | Non-blocking callbacks subscribed to the engine's event stream. |
| Skills (markdown prompts) | **Manual-convert** | Content ports as prompt/orchestration logic; per-tool format, converted on first use (port-on-demand). Pi expresses extensions/skills as TS packages. |
| `settings.json` hook registration | **Dropped** | No CLI to register into; replaced by app config + the rebuilt in-process gate/event layer. |

### Domain Research Questions (the implementer validates these in the first slice)
- Does Pi's `tool_call` hook reliably gate ALL destructive paths (deny + modify) **un-bypassably from the model side**, and does that contract survive a Pi 0.x version bump? ("Un-bypassable" is an architectural inference today, not a Pi security guarantee — validate empirically: deny a `bash rm`, assert no side effect; attempt a same-named-tool shadow and an unregistered tool, confirm neither suppresses the host gate; re-verify on every Pi upgrade.)
- Does the same internal gate abstraction map cleanly onto the Claude Agent SDK's `canUseTool`, proving the engine is swappable behind the adapter interface?
- What is the minimal canonical conversation representation that round-trips through ≥2 providers' tool-call/tool-result serializations with NO lossy coercion, and survives a mid-session provider switch within the smaller target's context window?

## Constraints (CRITICAL)

- **API keys live only in the OS keychain via `keyring-rs`, on a hard read-deny list for the agent's file/shell tools; transcripts/logs redact key-shaped strings at write time.** Prevents multi-vendor key exfiltration via the agent's own file-read tool. Verify: the agent's file tool returns access-denied for the key-store path. (Not Stronghold — deprecated; not a plaintext config file.)
- **All model/tool output renders as inert text under a strict CSP (no inline scripts, no remote loads, never `innerHTML` of model/tool content), AND the Tauri capability manifest is audited as the security boundary.** Prevents the GUI XSS surface the terminal never had (prompt-injected tool output executing in the renderer with IPC reach), and prevents an over-broad fs/shell capability + XSS chaining into RCE.
- **The security gate is an in-process pre-execution gate at the engine's tool-dispatch site (Pi `tool_call` / Claude `canUseTool`) and MUST NOT depend on a wire protocol (ACP) or an external agent process (opencode/Goose/Paseo).** Those cannot guarantee pre-execution interception (verified). Prevents re-introducing the refuted "gate at the boundary" design.
- **Destructive/irreversible actions — file delete, writes outside the workspace root, `git push`/force-push, `rm` — are denied by the in-process gate pending explicit human confirmation, regardless of the model's decision.** Tool output is untrusted data; the model choosing to act is not authorization. The gate is un-bypassable from the model side.
- **Every file mutation passes through a checkpoint layer (shadow snapshot or diff journal) with a one-action revert to the pre-action bytes; deletes are soft (trash), never `unlink`.** Prevents irreversible bad edits; this layer is also the per-turn rewind axis of the north star (a confirm dialog is not a substitute).
- **Per-engine adapters normalize tool calls into ONE internal representation; the in-process gate REJECTS (never coerces) any call whose arguments fail the registered tool's schema before execution.** Prevents model-agnostic parsing silently editing the wrong file. Verify: the same tool call through every adapter normalizes to byte-identical internal output.
- **An enforced per-session and per-day spend ceiling, computed from each provider's real price table, hard-pauses for confirmation at the ceiling, with live running cost in the GUI.** Prevents token/dollar runaway. (An enforced ceiling that blocks, not a displayed number.)
- **The working tree is shared, not owned: detect external modification (mtime/hash) before any write; never auto-commit/push without confirmation.** Prevents clobbering concurrent edits from the maintainer's other editor.
- **Memory-server-unavailable and DB-schema-mismatch are detected at startup and surfaced LOUDLY; the harness never runs silently memoryless.** The exact class that silently dropped memory for 30+ phases of the predecessor kit. Migrate older schemas forward; single-writer (WAL) + atomic transactions; startup `integrity_check` quarantines a corrupt DB and restores the last good snapshot.
- **Desktop builds are signed/notarized; updates are explicit/opt-in with visible release notes and one-click rollback.** A silent background update is both an RCE vector and a violation of the "I own and control this" north star.
- **Scope guard: only the minimum daily loop (edit → run → review, one provider, with memory, behind the gate) is v1.** Every additional ported feature must clear a "used weekly" test before it is built. Prevents reimplementing the whole CLI ecosystem before having a usable tool.

## Success Vision

A desktop app the maintainer reaches for *instead of* the terminal within the first week of the thin slice — because it feels joyful and in control. The five control/joy axes are present and felt: changes are previewed and approved before they land; any turn rewinds in one action; every action is reachable by button, shortcut, or palette search; the agent's work streams visibly with ambient per-task status; artifacts preview instantly. Switching providers is a non-event. Decisions and memory carry across sessions, and the accumulated AML-domain context came across intact at cutover. The agent never silently does something irreversible or expensive — because a gate the maintainer *owns*, in his own process, sits in front of every destructive action and cannot be talked out of it by the model. Excellence is the maintainer preferring this surface to the CLI and trusting it with destructive operations because the rails are real.

## Exit Criteria (machine-checkable — proven by a running minimum loop, not prose)

The architecture is validated by a working v1 thin slice. Each criterion is a functional test the first slice must make pass (exact paths fixed during `/dev-plan`):

- [ ] `npm run tauri build` (or equivalent) produces a runnable, signed desktop bundle that launches.
- [ ] An end-to-end provider round-trip via the **embedded Pi SDK**: a prompt from the GUI reaches one provider and streams a visible response — `tests/e2e/provider-roundtrip` exits 0.
- [ ] The same internal engine-adapter interface drives a **second engine (Claude Agent SDK)** through the identical gate path — `tests/e2e/second-adapter` exits 0 (proves engine-neutrality).
- [ ] The Python MCP memory server mounts and round-trips: a memory written via the GUI is read back after a session restart — `tests/e2e/memory-roundtrip` exits 0.
- [ ] **The in-process gate denies a seeded destructive tool call** (`bash rm` / out-of-workspace write) and the side effect never occurs — `tests/security/destructive-gate` exits 0.
- [ ] **A model-side bypass attempt** (a custom tool shadowing a built-in by name; an unregistered tool) cannot suppress the host gate — `tests/security/gate-bypass-resistance` exits 0.
- [ ] A file edit routed through the checkpoint layer reverts to the exact pre-edit bytes in one action — `tests/checkpoint/revert-bytes` exits 0.
- [ ] The agent's file-read tool returns access-denied for the key-store path — `tests/security/key-store-deny` exits 0.
- [ ] Prompt-injected tool output (`<script>`, `onerror=`, remote-load attempts) renders inert and does not execute, and trips a CSP violation report — `tests/security/inert-render` exits 0.
- [ ] A hard interrupt from the GUI cancels an in-flight/hung tool call within ≤2s of the user action — `tests/control/interrupt-hung-tool` exits 0.
- [ ] Driving session cost past the configured ceiling triggers a hard pause-for-confirmation, not merely a displayed number — `tests/control/spend-ceiling` exits 0.
- [ ] With the memory server stopped, startup surfaces a loud memory-unavailable state and refuses to run silently memoryless — `tests/integrity/memory-unavailable` exits 0.
- [ ] A file modified externally between the agent's read and its write is detected and the write is held — `tests/safety/external-modification` exits 0.
- [ ] The same tool call serialized through ≥2 provider adapters normalizes to byte-identical internal representation — `tests/adapters/normalize-identical` exits 0.

## Checkpoints

- **After the engine spike** (Pi SDK embedded in-process, one provider streaming to the surface, AND the `tool_call` gate denying a seeded destructive call): report. The gate is part of the spike, not a later add. Confirm Pi vs (Claude-SDK / Vercel-AI-SDK) before building further.
- **After the second-adapter proof** (Claude Agent SDK through the same gate interface): report — this validates the engine is swappable, not Pi-locked.
- **After the memory-server mount + round-trip:** report — validates the spine ports as-is.
- **After the security rails** (keychain deny, CSP/inert render + capability-manifest audit, in-process destructive-gate + bypass-resistance, checkpoint/revert): report. These are the irreversible-harm rails; do NOT enable daily-driver use on the live repo until all pass.
- **If Pi's gate proves bypassable from the model side, or its `tool_call`/`event.input` contract is too unstable across versions:** STOP and escalate — fall to the Claude Agent SDK adapter or to building the loop on Vercel AI SDK (maintainer decision, not autonomous).
- **If the existing memory-DB / dev-wiki import is lossy versus the originals:** STOP — do not cut over amnesiac.

## Assumptions

- **Pi's `tool_call` extension hook provides an un-bypassable in-process deny/modify gate over all tool calls (built-ins + custom).** If false (bypassable, or the hook contract churns unacceptably): fall to the Claude Agent SDK `canUseTool` adapter (Anthropic-only) for the gate, or build the loop on Vercel AI SDK and own the tool dispatch directly. The internal gate abstraction is engine-neutral by design.
- **Pi's MIT core (agent loop + `tool_call` hook) stays available under MIT.** If false (RFC-0015 open-core drift moves the gate primitive behind Fair Source/proprietary, or Earendil's single-vendor roadmap closes a depended-on capability): pin and fork the last MIT version, or switch adapters (Claude SDK / Vercel AI SDK).
- **`keyring-rs` provides OS-keychain access under Tauri on the maintainer's platform (macOS first).** If false: route keys through a separate, non-agent-reachable credential helper; never plaintext config.
- **The security gate does not, and must not, rely on ACP or an external engine process** (verified: neither can guarantee pre-execution interception). If a future ACP version makes client-side mandatory interception first-class, re-evaluate the external-agent import path; until then, in-process only.
- **The Python MCP memory server runs unchanged under the new app via MCP stdio.** If false: the defect is at the host's MCP-client mount, not the server — fix the mount.
- **The existing memory-DB schema + dev-wiki markdown are importable with a verifiable round-trip against the originals.** If false: treat import as a gated migration sub-project; do not declare cutover until it matches.
- **"Model-agnostic" at v1 means ≥2 providers usable interchangeably (including a mid-session switch), not all 25+.** If false (only one provider ever works end-to-end): the model-agnostic thesis is unproven — surface it rather than ship a single-provider build dressed as agnostic.
