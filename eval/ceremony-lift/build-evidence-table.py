#!/usr/bin/env python3
"""Phase 86 — generate evidence-table.md from corpus-manifest.md + the orchestrator's
classification map (every non-default classification rests on a re-execution-log.md
entry or the pinned downgrade rule; agent prose was candidate-generation only).

Defaults: debrief-capture rows -> consumption-grade-capped (re-presentation class;
uses-counter caveat); all other rows -> zero-catch unless mapped below.
"""

CAVEAT_DEFAULT = "agent-counterfactual residual applies"
CAVEAT_CONSUMPTION = ("re-presentation class: cannot support keep; [uses:N] seeded at 1, "
                      "increment discipline unknown")
CAVEAT_BUDGET = "pre-fix recoverable via transcript-extraction; not re-executed (budget)"
CAVEAT_UNREC = "pre-fix unrecoverable (folded before commit); pinned downgrade"

# (session-prefix, class, occurrence-index-within-session-class) -> (classification, reexec, caveat)
MAP = {
    ("74a6533b", "review-gate-reviewer", 0): (
        "outcome-grade-admitted", "re-execution-log.md#r-ph85-review-gate",
        "agent-counterfactual residual; audit DRIFT verdict environment-coupled"),
    ("7c3c3cfb", "dev-plan-orchestration", 0): (
        "outcome-grade-admitted", "re-execution-log.md#r-ph82-a1-bit",
        "bit-record basis, not gate-counterfactual; gateless-agent counterfactual unmeasured"),
    ("b9587f39", "dev-plan-orchestration", 0): (
        "outcome-grade-admitted", "re-execution-log.md#r-ph83-a2-bit",
        "bit-record basis, not gate-counterfactual; gateless-agent counterfactual unmeasured"),
    ("4548dee3", "dev-plan-orchestration", 0): (
        "outcome-grade-admitted", "re-execution-log.md#r-ph84-a1-bit",
        "bit-record basis, not gate-counterfactual; gateless-agent counterfactual unmeasured"),
    ("74a6533b", "dev-plan-orchestration", 0): (
        "outcome-grade-admitted", "re-execution-log.md#r-ph85-a2-bit",
        "bit-record basis, not gate-counterfactual; gateless-agent counterfactual unmeasured"),
    ("4548dee3", "review-gate-reviewer", 0): (
        "ambiguous-downgrade", "-", CAVEAT_BUDGET + "; candidate: 4 MEDIUM findings (Ph84)"),
    ("e2e6d848", "approach-reviewer", 0): (
        "ambiguous-downgrade", "-", CAVEAT_UNREC + "; candidate: 4 CRITICAL design flaws folded (Ph80)"),
    ("a3ded0d7", "spec-generation", 0): (
        "ambiguous-downgrade", "-", CAVEAT_UNREC + "; candidate: C1-C4 folded pre-pre-reg (Ph78)"),
    ("7c3c3cfb", "spec-generation", 0): (
        "ambiguous-downgrade", "-", CAVEAT_UNREC + "; candidate: >10-defects STOP threshold fired (Ph82)"),
    ("4d08872a", "spec-generation", 0): (
        "ambiguous-downgrade", "-", CAVEAT_UNREC + "; candidate: anti-retrofit ordering hazard pinned (Ph77)"),
    ("74a6533b", "plan-reviewer", 0): (
        "ambiguous-downgrade", "-", CAVEAT_UNREC + "; candidate: checkpoint-discipline findings (Ph85)"),
}

rows = []
with open("corpus-manifest.md") as fh:
    for line in fh:
        if not line.startswith("| ") or line.startswith("| session"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) != 4 or cells[3] == "non-ceremony":
            continue
        rows.append(cells)  # session, ts, label, class

seen = {}
out = []
for i, (session, ts, label, cls) in enumerate(rows, 1):
    key = (session[:8], cls)
    occ = seen.get(key, 0)
    seen[key] = occ + 1
    if cls == "debrief-capture":
        c, ptr, cav = "consumption-grade-capped", "-", CAVEAT_CONSUMPTION
    else:
        c, ptr, cav = MAP.get((session[:8], cls, occ),
                              ("zero-catch", "-", CAVEAT_DEFAULT))
    out.append((f"d{i}", session, ts[:10], cls, label, c, ptr, cav))

with open("evidence-table.md", "w") as fh:
    w = fh.write
    w("# Demand-Evidence Table — ceremony dispatches, Phases 76–85 (frozen corpus)\n\n")
    w("Verdict basis: re-execution-log.md entries (orchestrator-executed) + the pinned\n")
    w("downgrade rule. Candidates sourced from agent prose are NOT verdict evidence.\n\n")
    w("| id | session | date | step | label | evidence-class | reexec | caveat |\n")
    w("|---|---|---|---|---|---|---|---|\n")
    for r in out:
        w("| " + " | ".join(r) + " |\n")
    w("\n## Table-level caveats\n\n")
    w("- KNOWN UNDER-ENUMERATION: review-gate dispatches for Phases 81/82/83 are\n")
    w("  journal-narrated but absent from the manifest (their sessions fall outside the\n")
    w("  first-timestamp window or used unmatched labels). The review-gate denominator\n")
    w("  (3) undercounts by up to 3. The anchor control covers Phase 85 only.\n")
    w("- MDE guard (pre-registration ## MDE): review-gate-reviewer has 1 admitted event\n")
    w("  / 3 enumerated dispatches — BELOW the 3-event floor: zero/low counts for\n")
    w("  reviewer steps are statistically uninformative; cut requires expected-cost\n")
    w("  arithmetic, never the zero alone.\n")
    w("- Consumption rows: working-knowledge counters cannot distinguish seeding from\n")
    w("  retrieval; citation trails exist in decision articles but were not\n")
    w("  independently re-executed this phase.\n")
    cls_counts = {}
    for r in out:
        cls_counts[r[5]] = cls_counts.get(r[5], 0) + 1
    w("\nCLASS-COUNTS: " + " ".join(f"{k}={v}" for k, v in sorted(cls_counts.items())) + "\n")
print(f"wrote evidence-table.md ({len(out)} rows)")
