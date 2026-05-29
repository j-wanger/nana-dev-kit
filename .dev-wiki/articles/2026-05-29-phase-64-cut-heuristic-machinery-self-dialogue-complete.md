---
title: "Phase 64 complete — Cut heuristic scoring machinery + self-dialogue (batched double-renumber)"
aliases: ["2026-05-29-phase-64-cut-heuristic-machinery-self-dialogue-complete"]
category: journal
tags: [phase-64, deadweight-cut, heuristic-machinery, self-dialogue, renumber, subtraction, complete]
parents: [phase-64-cut-heuristic-scoring-machinery-self-dialogue]
created: 2026-05-29
updated: 2026-05-29
source: debrief
---

Executed the top item of the Phase-63 remediation roadmap: removed the never-fired Cognitive Enhancement scoring loop (matcher → judge → counter-update → lifecycle → dashboard) and the net-neutral self-dialogue step, **keeping** the 17 `wiki/heuristics/*.md` articles (live `test_templates`/`test_companions` fixtures + the eval/reasoning injection corpus). The subtraction is the machinery, never the knowledge. Net −457 lines.

**Removed:** 8 files (5 dev-plan companions: matcher/judge-prompt/counter-update/lifecycle/self-dialogue-prompt; `dev-debrief/heuristic-capture.md`; `scripts/heuristic-dashboard.py`; `tests/test_heuristic_evolution.sh`) + 2 eval/corpus scenarios + the `dashboard` Makefile target + 5 stale hot-cache entries. **Walked upstream** — cut both the dev-plan consumer (Step 13 heuristic-judge sub-items 6-7) and the dev-debrief producer (Step 7 heuristic-capture, the counter-writer), not just the consumer.

**The double-renumber was the principal risk and it bit as predicted.** dev-plan 12-18→11-17 and dev-debrief 8-26→7-25 (incl. the `debrief-finalization.md` companion 23-25→22-24). I renumbered with an ascending `s/Step N/Step N-1/` sed — which matched only the **singular** "Step N" form and **missed** (a) bare `#### 16a`-`16i` sub-step headings (no "Step" word) and (b) plural `Steps N-M`/`Steps N, M` range/list forms. `test_step_numbering.sh` passed anyway because it validates `### Step N:` headings only — exactly the blind spot the Phase-64 spec's adversarial-constraint pass flagged. The **review gate caught it** (HIGH×2 + MEDIUM×2 + LOW×1), I fixed all of them, and a follow-up completeness grep caught 2 more (`compaction-anchors-spec`, `artifact-writer-prompt`). Durable lesson: a renumber sweep must match bare-number sub-headings AND plural `Steps` forms, not just `Step N` — and the gap-free heading test is necessary but not sufficient; reference-resolution needs its own check.

**Eval-total-is-dynamic confirmed** (spec-reviewer's catch): `eval-runner.sh` counts `scenario.json`, so deleting 2 dirs yielded 52/52 with zero count-literal edits — the only count edits needed were the README's stated counts (54→52, 13→12), enforced by `test_templates`. **Hot-cache prune** went through the Phase-62 curator: removed the 5 entries describing removed machinery as operational (kept article/IRON/eval-methodology/negative-result entries), and a curator dogfood on the edited cache was a byte-identical no-op (100→95 entries, fixed point). The two `[pinned]`-adjacent stale-file mentions (self-dialogue-prompt, heuristic-capture) were trimmed in-place.

**Verification:** `make test` green (12 scripts) · `make eval` 52/52 · `test_step_numbering` gap-free (dev-plan 1..17, dev-debrief 1..25) · `test_companions`/`test_registration` ✓ · no-dangling-machinery grep CLEAN · 17 articles + `eval/reasoning/self-dialogue-injection.md` untouched. 4/4 tasks ✓. Governed by [[cut-heuristic-scoring-keep-articles]], [[batch-self-dialogue-with-heuristic-renumber]], [[eval-total-is-dynamic]]. **Delivered + accepted + committed.** Next: /dev-plan Phase 65 (remaining roadmap: build the real-agentic eval [gated on approval]; retire the confounded comparison arm; session-start.d global drift).
