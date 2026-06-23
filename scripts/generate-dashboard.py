#!/usr/bin/env python3
"""Generate the decisioning cockpit (Phase 107) — a tabbed `Status | Decide | Workflow` page that is
the PRIMARY /dev-plan direction-gate surface, render-only.

5th member of the docs/ HTML-generator family. It does NOT copy the Phase-99 direction render: it
IMPORTS render_options / render_assumptions / esc / load_brief / validate_brief / is_stale /
get_active_phase_line from the sibling generate-direction.py (anti-drift — the option/assumption
render is the same code Ph99 uses). The same pure render_dashboard(panes, interactive=...) is reused
by the ephemeral decision-server to serve the interactive act-from-page form; `main()` here always
emits the static, form-LESS page.

Phase 107 changes (the maintainer found the Ph106 page unusable): a tabbed cockpit; per-option
REASONING + CONSEQUENCES laid out for comparison (the Decide tab); a LOUD stale-brief guard — when the
brief's phase != the active phase the Decide tab shows a danger banner and NO submittable form (a stale
gate is never silently decidable); the Workflow tab re-renders the harness breakdown natively (T3).

Monitoring panes degrade gracefully (a missing/restructured living doc never crashes the page), but the
direction brief FAILS LOUD when present-but-malformed (controls-first, HEU-012).

Usage:
    python3 scripts/generate-dashboard.py [--state PATH] [--brief PATH] [--output PATH] [--dry-run]
Defaults: --state .dev-wiki/_CURRENT_STATE.md, --brief .dev-wiki/direction-brief.json,
          --output docs/dashboard.html
"""

import argparse
import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WIKI = ROOT / ".dev-wiki"


def _load_direction_module():
    """Load the sibling generate-direction.py by path (its hyphenated name is not a valid module
    identifier, so a plain import is impossible). Returns the module so we IMPORT its render
    functions rather than copy them — a divergence between the two dashboards can't happen."""
    path = Path(__file__).with_name("generate-direction.py")
    spec = importlib.util.spec_from_file_location("generate_direction", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


_gd = _load_direction_module()
esc = _gd.esc
render_options = _gd.render_options
render_assumptions = _gd.render_assumptions
load_brief = _gd.load_brief
validate_brief = _gd.validate_brief
is_stale = _gd.is_stale
get_active_phase_line = _gd.get_active_phase_line
_phase_num = _gd._phase_num


def _load_workflow_module():
    """Load generate-workflow.py by path so the Workflow tab re-renders the harness breakdown
    natively (Phase 107 T3) — its standalone docs/workflow.html generator is untouched. Best-effort:
    a missing/broken workflow generator must NOT crash the cockpit (render-only, fail-soft)."""
    try:
        path = Path(__file__).with_name("generate-workflow.py")
        spec = importlib.util.spec_from_file_location("generate_workflow", path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod
    except Exception:
        return None


# Status sections surfaced in the monitoring digest. "Recognized" = at least one is present; a
# present-but-restructured _CURRENT_STATE (none of these found) gets a DISTINCT warning marker, never
# the silent "(section absent)" placeholder — so a restructured doc can't masquerade as a missing one.
STATUS_SECTIONS = ["Recommended Next Action", "Active Phase", "Blockers and Open Questions"]
ABSENT = "(section absent)"


def split_sections(text):
    """Split a markdown doc into {h2-header: body} on '## ' lines (digesting happens at render)."""
    sections = {}
    cur, buf = None, []
    for line in text.splitlines():
        if line.startswith("## "):
            if cur is not None:
                sections[cur] = "\n".join(buf).strip()
            cur, buf = line[3:].strip(), []
        elif cur is not None:
            buf.append(line)
    if cur is not None:
        sections[cur] = "\n".join(buf).strip()
    return sections


def load_status(path):
    """Best-effort: {present, recognized, sections}. NEVER raises — monitoring panes must render even
    when a living doc is missing or restructured (render-only consumer, not a parser gate)."""
    try:
        text = Path(path).read_text()
    except OSError:
        return {"present": False, "recognized": False, "sections": {}}
    sections = split_sections(text)
    recognized = any(h in sections for h in STATUS_SECTIONS)
    return {"present": True, "recognized": recognized, "sections": sections}


def _digest(body, limit=700):
    """First block of a section, escaped + length-capped for a scannable digest. Escape BEFORE
    appending the raw `&hellip;` so html.escape doesn't turn it into `&amp;hellip;`."""
    body = body.strip()
    if len(body) > limit:
        return esc(body[:limit].rsplit(" ", 1)[0]) + " &hellip;"
    return esc(body)


def render_status(status):
    if not status["present"]:
        return f'<p class="muted">{ABSENT} &mdash; _CURRENT_STATE.md not found</p>'
    if not status["recognized"]:
        # Present but NONE of the expected sections — a DISTINCT marker, not the silent absent
        # placeholder. A restructured (non-empty) doc must look different from a missing one.
        return ('<p class="warn">&#9888; unrecognized _CURRENT_STATE structure &mdash; none of the '
                f'expected sections ({esc(", ".join(STATUS_SECTIONS))}) were found '
                '(the document may have been restructured)</p>')
    blocks = ""
    for h in STATUS_SECTIONS:
        body = status["sections"].get(h)
        rendered = _digest(body) if body else ABSENT
        blocks += (f'<div class="status-section"><h3>{esc(h)}</h3>'
                   f'<div class="status-body">{rendered}</div></div>\n')
    return blocks


def render_workflow_tab():
    """The Workflow tab — the harness breakdown re-rendered NATIVELY into the cockpit's visual system
    (Phase 107 T3). Imports fragment fns from generate-workflow.py; fail-soft to a placeholder so a
    missing/broken workflow generator never breaks the cockpit (render-only)."""
    wf = _load_workflow_module()
    if wf is not None and hasattr(wf, "render_fragments"):
        try:
            return wf.render_fragments()
        except Exception as e:  # never let the workflow tab crash the page
            return f'<p class="muted">Workflow breakdown unavailable ({esc(e)}).</p>'
    return ('<p class="muted">Workflow breakdown &mdash; run `make workflow` for the full harness '
            'view.</p>')


def render_decide(brief, interactive, stale):
    """The Decide tab: the recommendation, options laid out for comparison (reasoning + consequences),
    the cost-sorted assumptions, and — only on a FRESH, phase-matching brief in interactive mode — the
    decision form. A stale (phase-mismatch) brief shows a LOUD danger banner and NO submittable form."""
    if brief is None:
        return ('<p class="muted">No active direction gate. '
                'Run a <code>/dev-plan</code> gate to decide here.</p>')
    html = ""
    if stale:
        bp = brief.get("phase", "?")
        html += (
            '<div class="banner danger" role="alert"><span class="banner-tag">Stale gate</span>'
            f'This brief is from <strong>phase {esc(bp)}</strong>, which is not the active phase. '
            'It is not decidable here &mdash; regenerate the gate before acting. '
            'Shown below for reference only.</div>\n'
        )
    html += (f'<div class="recommend"><span class="tag">Recommendation</span>'
             f'{esc(brief.get("recommendation", ""))}</div>\n')
    html += '<h3 class="sec-head">Options</h3>\n' + render_options(brief.get("options", []))
    html += '<h3 class="sec-head">Assumptions <span class="sub">cost-sorted &middot; position to decide</span></h3>\n<table>\n'
    html += "<tr><th>ID</th><th>Cost</th><th>Assumption</th><th>Position</th></tr>\n"
    html += render_assumptions(brief.get("assumptions", [])) + "</table>\n"
    if interactive and not stale:
        html += render_decision_form(brief)
    return html


def render_decision_form(brief):
    """The act-from-page form — ONLY emitted on the served (interactive) page for a fresh brief. Builds
    the decision-response JSON client-side and POSTs it same-origin to /decision (no clipboard, no File
    System Access API; the served origin makes the POST's Origin header trustworthy)."""
    options = brief.get("options", [])
    assumptions = brief.get("assumptions", [])
    opt_radios = "".join(
        f'<label class="opt-radio"><input type="radio" name="option_label" '
        f'value="{esc(o.get("label",""))}" required> {esc(o.get("label",""))}</label>\n'
        for o in options
    )
    assum_blocks = ""
    for a in assumptions:
        aid = a.get("id", "")
        radios = "".join(
            f'<label class="pos-radio"><input type="radio" name="pos_{esc(aid)}" '
            f'value="{esc(pos)}" required> {esc(pos)}</label> '
            for pos in ("accept", "reject", "don't-know")
        )
        assum_blocks += (
            f'<div class="assum"><div class="assum-text"><strong>{esc(aid)}</strong> '
            f'{esc(a.get("text",""))}</div><div class="assum-pos">{radios}</div>'
            f'<input class="assum-note" type="text" name="notes_{esc(aid)}" placeholder="notes (optional)"></div>\n'
        )
    ids_json = json.dumps([a.get("id", "") for a in assumptions])
    phase_json = json.dumps(brief.get("phase", ""))
    nonce_json = json.dumps(brief.get("nonce", ""))
    gate_json = json.dumps(brief.get("gate_id", "direction"))
    return f"""
<h3 class="sec-head">Make the call</h3>
<form id="decision-form" class="decision-form">
  <fieldset><legend>Option</legend>
  {opt_radios}</fieldset>
  <fieldset><legend>Positions</legend>
  {assum_blocks}</fieldset>
  <label class="notes-label">Notes<br><textarea name="notes" rows="2"></textarea></label>
  <div class="submit-row"><button type="submit">Submit decision</button>
  <span id="result" class="result"></span></div>
</form>
<script>
(function() {{
  var PHASE = {phase_json}, NONCE = {nonce_json}, GATE_ID = {gate_json}, IDS = {ids_json};
  var f = document.getElementById('decision-form');
  f.addEventListener('submit', function(e) {{
    e.preventDefault();
    var fd = new FormData(f);
    var assumptions = IDS.map(function(id) {{
      return {{ id: id, position: fd.get('pos_' + id) || '', notes: fd.get('notes_' + id) || '' }};
    }});
    var payload = {{ phase: PHASE, gate_id: GATE_ID, brief_nonce: NONCE,
      option_label: fd.get('option_label') || '', assumptions: assumptions, notes: fd.get('notes') || '' }};
    fetch('/decision', {{ method: 'POST', headers: {{ 'Content-Type': 'application/json' }}, body: JSON.stringify(payload) }})
      .then(function(r) {{ return r.text().then(function(t) {{ return {{ ok: r.ok, t: t }}; }}); }})
      .then(function(res) {{ document.getElementById('result').textContent =
        res.ok ? '\\u2713 Decision received \\u2014 you can close this tab.' : ('\\u2717 Rejected: ' + res.t); }})
      .catch(function(err) {{ document.getElementById('result').textContent = '\\u2717 Error: ' + err; }});
  }});
}})();
</script>
"""


# Decisioning cockpit visual system (Phase 107). A dark "control instrument" console — deliberately NOT
# the system-font default the maintainer rejected. Monospace carries structure (tabs, labels, eyebrows,
# IDs — the instrument vernacular of a developer harness); a system sans carries prose (reasoning,
# consequences, status). Semantic color is load-bearing: green = go/recommended, amber = cost/caution,
# red = reject/stale-danger. Signature: option cards with consistently-placed Reasoning(green)/
# Consequences(amber) zones so the trade-off is legible scanning down.
_CSS = """
  :root {
    --bg: #0f1419; --surface: #161c24; --surface-2: #1b232d; --line: #2a3441;
    --ink: #e6edf3; --ink-dim: #9aa7b6; --ink-faint: #6b7888;
    --go: #3fb950; --go-dim: #2ea043; --caution: #d29922; --danger: #f85149;
    --mono: "SF Mono", "JetBrains Mono", "Fira Mono", ui-monospace, Menlo, Consolas, monospace;
    --sans: -apple-system, "Segoe UI", system-ui, Roboto, sans-serif;
  }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--ink); font-family: var(--sans); line-height: 1.6; font-size: 15px; }
  code { font-family: var(--mono); font-size: 0.9em; background: var(--surface-2); padding: 0.1em 0.35em; border-radius: 4px; }
  .topbar { position: sticky; top: 0; z-index: 5; background: rgba(15,20,25,0.92); backdrop-filter: blur(6px);
            border-bottom: 1px solid var(--line); padding: 0.9em 1.4em 0; }
  .ident { display: flex; align-items: baseline; gap: 0.7em; flex-wrap: wrap; }
  .phase-num { font-family: var(--mono); font-weight: 700; font-size: 1.05em; color: var(--go);
               letter-spacing: 0.02em; }
  .phase-name { font-size: 1.15em; font-weight: 600; }
  .mode { font-family: var(--mono); font-size: 0.74em; color: var(--ink-faint); text-transform: uppercase;
          letter-spacing: 0.08em; margin: 0.25em 0 0.7em; }
  .tabs { display: flex; gap: 0.2em; margin-top: 0.2em; }
  .tab { font-family: var(--mono); font-size: 0.82em; letter-spacing: 0.04em; text-transform: uppercase;
         color: var(--ink-dim); background: none; border: 0; border-bottom: 2px solid transparent;
         padding: 0.55em 1.1em; cursor: pointer; transition: color 0.12s, border-color 0.12s; }
  .tab:hover { color: var(--ink); }
  .tab.active { color: var(--ink); border-bottom-color: var(--go); }
  main { max-width: 880px; margin: 0 auto; padding: 1.8em 1.4em 4em; }
  .panel { display: none; }
  .panel.active { display: block; animation: fade 0.18s ease both; }
  @keyframes fade { from { opacity: 0; transform: translateY(3px); } to { opacity: 1; transform: none; } }
  .sec-head { font-family: var(--mono); font-size: 0.82em; text-transform: uppercase; letter-spacing: 0.06em;
              color: var(--ink-dim); margin: 1.8em 0 0.7em; font-weight: 600; }
  .sec-head .sub { text-transform: none; letter-spacing: 0; color: var(--ink-faint); font-weight: 400; }
  h3 { font-size: 1em; }
  .muted { color: var(--ink-faint); font-style: italic; }
  .warn { background: #2a230f; border-left: 4px solid var(--caution); border-radius: 8px; padding: 0.8em 1.1em;
          color: #f0d38a; }
  .banner { border-radius: 10px; padding: 1em 1.2em; margin: 0 0 1.3em; font-size: 0.96em; }
  .banner.danger { background: #2d1314; border: 1px solid var(--danger); color: #ffb4ad; }
  .banner-tag { display: block; font-family: var(--mono); font-size: 0.7em; text-transform: uppercase;
                letter-spacing: 0.08em; color: var(--danger); font-weight: 700; margin-bottom: 0.25em; }
  .recommend { background: linear-gradient(180deg, #12251a, #0f1f17); border: 1px solid #1f5132;
               border-left: 4px solid var(--go); border-radius: 10px; padding: 1.1em 1.3em; margin: 0.3em 0 0.5em;
               font-size: 1.05em; }
  .recommend .tag { display: block; font-family: var(--mono); font-size: 0.7em; text-transform: uppercase;
                    letter-spacing: 0.09em; color: var(--go); font-weight: 700; margin-bottom: 0.35em; }
  .status-section { margin: 0.9em 0; }
  .status-body { color: var(--ink-dim); font-size: 0.92em; white-space: pre-wrap; background: var(--surface);
                 border: 1px solid var(--line); border-radius: 8px; padding: 0.7em 0.9em; }
  .option { border: 1px solid var(--line); border-radius: 10px; padding: 1em 1.2em; margin: 0.8em 0;
            background: var(--surface); }
  .option.chosen-card { border-color: var(--go); }
  .opt-head { display: flex; align-items: center; gap: 0.6em; margin-bottom: 0.35em; flex-wrap: wrap; }
  .opt-label { font-family: var(--mono); font-weight: 700; font-size: 0.98em; letter-spacing: 0.01em; }
  .opt-desc { color: var(--ink-dim); font-size: 0.95em; }
  .opt-reasoning, .opt-consequences { font-size: 0.93em; margin-top: 0.7em; padding: 0.55em 0.8em;
            border-radius: 7px; background: var(--surface-2); border-left: 3px solid var(--line); }
  .opt-reasoning { border-left-color: var(--go); }
  .opt-consequences { border-left-color: var(--caution); }
  .opt-tag { display: block; font-family: var(--mono); font-size: 0.66em; text-transform: uppercase;
             letter-spacing: 0.07em; font-weight: 700; margin-bottom: 0.2em; opacity: 0.85; }
  .opt-reasoning .opt-tag { color: var(--go); }
  .opt-consequences .opt-tag { color: var(--caution); }
  .badge { font-family: var(--mono); font-size: 0.64em; text-transform: uppercase; letter-spacing: 0.05em;
           padding: 0.2em 0.55em; border-radius: 20px; font-weight: 700; }
  .badge.rec { background: #12351f; color: var(--go); border: 1px solid #1f5132; }
  .badge.chosen { background: #1b2733; color: #9ecbff; border: 1px solid #2b4a6b; }
  table { width: 100%; border-collapse: collapse; margin: 0.6em 0; font-size: 0.92em; }
  th, td { text-align: left; padding: 0.55em 0.7em; border-bottom: 1px solid var(--line); vertical-align: top; }
  th { font-family: var(--mono); color: var(--ink-dim); font-size: 0.74em; text-transform: uppercase;
       letter-spacing: 0.05em; font-weight: 600; }
  td.aid { font-family: var(--mono); font-weight: 700; color: var(--ink); white-space: nowrap; }
  .cost { font-family: var(--mono); font-weight: 700; text-transform: uppercase; font-size: 0.78em; }
  .pos { display: inline-block; color: #fff; padding: 0.15em 0.6em; border-radius: 5px; font-size: 0.78em;
         font-weight: 700; white-space: nowrap; font-family: var(--mono); }
  .resolution { color: var(--ink-faint); font-size: 0.88em; margin-top: 0.3em; font-style: italic; }
  .decision-form fieldset { border: 1px solid var(--line); border-radius: 10px; margin: 0.9em 0; padding: 0.9em 1.1em;
            background: var(--surface); }
  .decision-form legend { font-family: var(--mono); font-size: 0.78em; text-transform: uppercase; letter-spacing: 0.05em;
            color: var(--ink-dim); padding: 0 0.5em; }
  .opt-radio { display: block; padding: 0.25em 0; }
  .assum { margin: 0.7em 0; padding-bottom: 0.6em; border-bottom: 1px solid var(--line); }
  .assum-pos { margin: 0.35em 0; }
  .pos-radio { margin-right: 0.9em; white-space: nowrap; font-family: var(--mono); font-size: 0.86em; }
  .assum-note, .notes-label textarea { width: 100%; box-sizing: border-box; margin-top: 0.3em; background: var(--bg);
            color: var(--ink); border: 1px solid var(--line); border-radius: 6px; padding: 0.45em 0.6em; font-family: inherit; }
  .notes-label { display: block; margin: 0.5em 0; color: var(--ink-dim); font-size: 0.9em; }
  .submit-row { margin-top: 1em; display: flex; align-items: center; gap: 1em; }
  .decision-form button { font-family: var(--mono); background: var(--go-dim); color: #04130a; border: 0;
            border-radius: 8px; padding: 0.6em 1.4em; font-size: 0.9em; font-weight: 700; cursor: pointer;
            text-transform: uppercase; letter-spacing: 0.04em; transition: background 0.12s; }
  .decision-form button:hover { background: var(--go); }
  .result { font-weight: 700; font-family: var(--mono); font-size: 0.9em; }
  input:focus-visible, button:focus-visible, textarea:focus-visible, .tab:focus-visible {
            outline: 2px solid var(--go); outline-offset: 2px; }
  .footer { max-width: 880px; margin: 0 auto; padding: 1.4em; border-top: 1px solid var(--line);
            color: var(--ink-faint); font-size: 0.8em; font-family: var(--mono); }
  @media (max-width: 600px) { .tabs { flex-wrap: wrap; } main { padding: 1.2em 1em 3em; } }
  @media (prefers-reduced-motion: reduce) { .panel.active { animation: none; } }
"""


_TAB_JS = """
(function() {
  var tabs = Array.prototype.slice.call(document.querySelectorAll('.tab'));
  var panels = Array.prototype.slice.call(document.querySelectorAll('.panel'));
  tabs.forEach(function(t) {
    t.addEventListener('click', function() {
      tabs.forEach(function(x) { x.classList.remove('active'); x.setAttribute('aria-selected', 'false'); });
      panels.forEach(function(x) { x.classList.remove('active'); });
      t.classList.add('active'); t.setAttribute('aria-selected', 'true');
      var p = document.getElementById(t.dataset.tab);
      if (p) p.classList.add('active');
    });
  });
})();
"""


def render_dashboard(panes, interactive=False):
    """Pure render: turn a panes dict into the full cockpit HTML. Reused verbatim by the ephemeral
    decision-server (interactive=True serves the act-from-page form on a fresh, phase-matching brief).
    `panes` keys: phase, phase_name, generated, status (from load_status), brief (validated dict or
    None), stale (bool — brief phase != active phase)."""
    phase = panes.get("phase", "?")
    phase_name = panes.get("phase_name", "")
    generated = panes.get("generated", "")
    brief = panes.get("brief")
    stale = bool(panes.get("stale"))
    mode = "Live gate — decide below" if interactive else "Monitor — read-only"

    status_html = render_status(panes["status"])
    decide_html = render_decide(brief, interactive, stale)
    workflow_html = render_workflow_tab()

    # Land on Decide when there is a gate to act on; otherwise Status (orientation).
    default_tab = "status" if brief is None else "decide"
    gen_line = f" &middot; generated {esc(generated)}" if generated else ""

    def tab(tid, label):
        active = " active" if tid == default_tab else ""
        sel = "true" if tid == default_tab else "false"
        return f'<button class="tab{active}" data-tab="{tid}" role="tab" aria-selected="{sel}">{label}</button>'

    def panel(tid, body):
        active = " active" if tid == default_tab else ""
        return f'<section id="{tid}" class="panel{active}" role="tabpanel">{body}</section>'

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cockpit: Phase {esc(phase)}</title>
<style>{_CSS}</style>
</head>
<body>
<header class="topbar">
  <div class="ident"><span class="phase-num">Phase {esc(phase)}</span><span class="phase-name">{esc(phase_name)}</span></div>
  <div class="mode">{esc(mode)}{gen_line}</div>
  <nav class="tabs" role="tablist">
    {tab("decide", "Decide")}
    {tab("status", "Status")}
    {tab("workflow", "Workflow")}
  </nav>
</header>
<main>
  {panel("decide", decide_html)}
  {panel("status", status_html)}
  {panel("workflow", workflow_html)}
</main>
<div class="footer">Decisioning cockpit (Phase 107) &middot; generate-dashboard.py &middot; {"submit drives the /dev-plan gate via the ephemeral decision-server." if interactive else "render-only monitor; a /dev-plan gate serves the live, decidable page."}</div>
<script>{_TAB_JS}</script>
</body>
</html>"""


def build_panes(state_path, brief_path, active_phase=None):
    """Assemble the panes dict from the live files. Status degrades gracefully; the brief FAILS LOUD
    (ValueError) when present-but-malformed (caught in main / the server). `active_phase` overrides the
    live active-phase line (tests inject it so the stale check is deterministic, not coupled to the
    live doc — the Ph80 leak guard)."""
    status = load_status(state_path)
    brief = None
    if Path(brief_path).exists():
        brief = load_brief(brief_path)  # validates; raises ValueError on malformed/missing-field
    if active_phase is None:
        active_phase = get_active_phase_line() or ""
    stale = bool(brief is not None and is_stale(brief, active_phase))
    if brief is not None:
        phase = brief.get("phase", "?")
        phase_name = brief.get("phase_name", "")
        generated = brief.get("generated", "")
    else:
        pn = _phase_num(active_phase)
        phase = pn if pn is not None else "?"   # phase 0 is falsy — keep it, don't fall to "?"
        phase_name = ""
        generated = ""
    return {"phase": phase, "phase_name": phase_name, "generated": generated,
            "status": status, "brief": brief, "stale": stale}


def main():
    parser = argparse.ArgumentParser(description="Generate the decisioning cockpit (render-only static page).")
    parser.add_argument("--state", default=str(WIKI / "_CURRENT_STATE.md"), help="_CURRENT_STATE.md path")
    parser.add_argument("--brief", default=str(WIKI / "direction-brief.json"), help="direction brief JSON path")
    parser.add_argument("--output", default=str(ROOT / "docs" / "dashboard.html"), help="output HTML path")
    parser.add_argument("--dry-run", action="store_true", help="report without writing HTML")
    args = parser.parse_args()

    try:
        panes = build_panes(args.state, args.brief)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    if args.dry_run:
        print(f"Phase: {panes['phase']}  status-present: {panes['status']['present']}  "
              f"status-recognized: {panes['status']['recognized']}  brief: {panes['brief'] is not None}  "
              f"stale: {panes['stale']}")
        print(f"Output (would write): {args.output}")
        return

    html = render_dashboard(panes, interactive=False)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html)
    print(f"Decisioning cockpit written to {out}", file=sys.stderr)


if __name__ == "__main__":
    main()
