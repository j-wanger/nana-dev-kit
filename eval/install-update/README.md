# eval/install-update — consumer-state fixtures + detection harness (Phase 93)

Apparatus for `install.sh --update` (the idempotent consuming-project re-sync mode). This
directory holds the **fixture manifests** and the README; the executable harness +
seeded controls live in `tests/test_install_update.sh`.

## What this is for

Consuming projects drift from the kit. `--project-local` cp-overwrites hook files and
upserts registrations, but it (1) never REMOVES cut hooks (the Phase-88 `detect-loop`
lingers — the observed 17/18/19-hook spread across edge-screener / edge-analyst / ai-game /
fate / aml-substrate), (2) can't dedupe Phase-79-style hand-patched duplicate registrations
(`register-settings.py` is upsert-only; DRQ-1 — distinct command strings invoking the same
script BOTH fire), and (3) signal-watch has NO kit hooks at all. `--update` reconciles all
three. Before any reconcile/dereg logic is trusted, the **detection harness** must be proven
to catch the defects it claims to fix.

## The three detectors (the instrument)

Deterministic, jq-over-`settings.local.json` + on-disk hook files. No LLM, no live state.

| detector | drift it surfaces | `--update` action |
|---|---|---|
| `detect_missing_hooks` | kit project hooks absent from the consumer | ADD |
| `detect_duplicate_registrations` | one script basename registered >1× (DRQ-1) | DEDUPE |
| `detect_cut_hooks` | a registered/present basename the current kit no longer ships | DEREG (destructive — T3 rails) |

## Drift-class fixtures

One directory = one drift class = one `manifest.json` ("a new drift class is one table row").
Fixtures are built **programmatically from the live `modules.json`** by the harness: it stands
up a synced baseline consumer with the *current* kit project-hook set (via the same
`register-settings.py --scope project-local` install.sh uses — faithful + stale-proof), then
applies the manifest's declared `mutations`. The manifest declares only the delta and the
expected detections — never a hardcoded copy of the kit hook list (which would rot).

| class | models | mutation | expected flags |
|---|---|---|---|
| `no-hooks` | signal-watch (no kit hooks at all) | `strip_all` | all hooks missing |
| `staged-detect-loop-ghost` | the 17/18/19-hook staged consumers | `add_ghost detect-loop.sh` | cut: `detect-loop.sh` |
| `phase79-duplicate-registration` | a pre-Phase-79 hand-patched consumer | `duplicate enforce-spec.sh` | dup: `enforce-spec.sh` |

### manifest schema

```json
{
  "class": "<dir name>",
  "models": "<which real consumer(s) this reproduces>",
  "mutations": [ { "op": "strip_all | add_ghost | duplicate", "script": "...", "event": "...", "matcher": "..." } ],
  "expect": {
    "cut_hooks": ["..."],
    "duplicate_registrations": ["..."],
    "missing_mode": "all | none"
  }
}
```

## Controls-first (clean-on-seed = instrument-dead)

Per [[qa-verification-sweep]] / [[HEU-012]]: a checker's clean verdict counts only because each
seeded defect is CAUGHT. The harness runs three seeded controls on a freshly-synced consumer:

1. **clean** — flags nothing (crying-wolf guard; a detector that always-flags fails here),
2. **seeded cut-hook** — a synthetic basename the kit doesn't ship MUST be flagged (a dead
   detector that always-returns-empty fails here),
3. **seeded duplicate registration** — a kept script given a second, distinct command string
   MUST be flagged.

Only a *discriminating* instrument passes all three. If a seeded control is not caught, the
suite reports `INSTRUMENT-DEAD` and the reconcile/dereg path is not to be trusted.

## Hermeticity

Every consumer is built under `mktemp -d`. The harness only READS `modules.json` /
`register-settings.py` and only WRITES inside the scratch consumer. No live consumer repo,
no `~/.claude`, no kit file is ever modified. This phase is BUILD + SANDBOX-VERIFY ONLY.
