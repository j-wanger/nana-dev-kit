# Phase 85 — eval diff note

Post-change `make eval`: **52/52 (100%)**, denominator unchanged, **zero flips** vs the Phase-84
close-out baseline (52/52). Expected: Phase-85 changes touch install.sh shipping, the drift
checker's comparison set, and modules.json's hook_dirs key — none of which any eval scenario
exercises (the corpus pipes events through hooks; it does not run the installer or the drift
checker). Run date: 2026-06-10.
