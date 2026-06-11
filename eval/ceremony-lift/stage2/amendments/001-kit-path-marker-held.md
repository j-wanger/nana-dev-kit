# Amendment 001 — kit-path marker held for the experiment window (2026-06-10, pre-unblinding)

Canary pre-check finding: the Ph85 session-start hooks (parity-shared, identical in both
arms) read `$HOME/.claude/.nana-dev-kit-path`, a HOME-level marker resolving to the kit
repo — a followable channel to kit-internal docs (the canary's answer). Maintainer ruling
(T4 checkpoint, 2026-06-10): the hooks ship AS-IS (they are the treatment);
`$HOME/.claude/.nana-dev-kit-path` is renamed to `.nana-dev-kit-path.p87-held` BEFORE the
first arm session and restored at close-out (T8). The hook reads fail open (`cat ... ||
true`), severing the indirection for BOTH arms equally. The canary pre-check's two known
hits (session-start.sh, session-start.d/cognitive-readiness.sh) are RULED parity-shared
under this hold; any OTHER `drq1|install-gap|nana-dev-kit` hit in the provision set still
stops setup. Substrate build is also pinned here: the live edge-screener checkout is
NEVER branch-switched — the setup branch is built in a separate clone at
/Users/jwang/p87-substrate/edge-screener (the addendum's pinned clone URL), with the
dirty surfaces copied in; live-tree restoration risk is structural zero, and the
snapshot+restore test below is belt-and-braces.
