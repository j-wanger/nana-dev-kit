#!/usr/bin/env python3
"""Generate the project-state dashboard (Phase 106) — an on-demand `make dashboard` page that
surfaces a thin PROJECT-STATUS digest + the live DIRECTION gate, render-only.

5th member of the docs/ HTML-generator family. It does NOT copy the Phase-99 direction render:
it IMPORTS render_options / render_assumptions / esc / load_brief / validate_brief from the
sibling generate-direction.py (anti-drift — the direction pane is rendered by the same code the
Ph99 dashboard uses). The same pure render_dashboard(panes, interactive=...) is reused by the
ephemeral decision-server (Phase 106 T4) to serve the interactive act-from-page form; `main()`
here always emits the static, form-LESS page.

Monitoring panes degrade gracefully (a missing/restructured living doc never crashes the page),
but the direction brief FAILS LOUD when present-but-malformed (controls-first, HEU-012).

Usage:
    python3 scripts/generate-dashboard.py [--state PATH] [--brief PATH] [--output PATH] [--dry-run]
Defaults: --state .dev-wiki/_CURRENT_STATE.md, --brief .dev-wiki/direction-brief.json,
          --output docs/dashboard.html
"""

import argparse
import importlib.util
import json
import re
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

# Status sections surfaced in the monitoring digest. "Recognized" = at least one is present; a
# present-but-restructured _CURRENT_STATE (none of these found) gets a DISTINCT warning marker,
# never the silent "(section absent)" placeholder — so a restructured doc can't masquerade as a
# missing one (the #1 dead-instrument guard).
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
    """Best-effort: {present, recognized, sections}. NEVER raises — monitoring panes must render
    even when a living doc is missing or restructured (render-only consumer, not a parser gate)."""
    try:
        text = Path(path).read_text()
    except OSError:
        return {"present": False, "recognized": False, "sections": {}}
    sections = split_sections(text)
    recognized = any(h in sections for h in STATUS_SECTIONS)
    return {"present": True, "recognized": recognized, "sections": sections}


def _digest(body, limit=700):
    """First block of a section, escaped + length-capped for a scannable digest. Escape the text
    BEFORE appending the raw `&hellip;` entity so html.escape doesn't turn it into `&amp;hellip;`
    (which would render as the literal text instead of an ellipsis)."""
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


def render_direction(brief, interactive):
    if brief is None:
        return '<p class="muted">(no active direction gate &mdash; .dev-wiki/direction-brief.json absent)</p>'
    html = f'<div class="recommend"><span class="tag">Recommendation</span>{esc(brief.get("recommendation", ""))}</div>\n'
    html += "<h3>Options</h3>\n" + render_options(brief.get("options", []))
    html += '<h3>Assumptions (cost-sorted) &amp; positions</h3>\n<table>\n'
    html += "<tr><th>ID</th><th>Cost</th><th>Assumption</th><th>Position</th></tr>\n"
    html += render_assumptions(brief.get("assumptions", [])) + "</table>\n"
    if interactive:
        html += render_decision_form(brief)
    return html


def render_decision_form(brief):
    """The act-from-page form — ONLY emitted on the served (interactive) page. Builds the
    decision-response JSON client-side and POSTs it same-origin to /decision (no clipboard, no
    File System Access API; the served origin makes the POST's Origin header trustworthy)."""
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
<h3>Make the call</h3>
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


_CSS = """
  body { font-family: -apple-system, system-ui, sans-serif; max-width: 960px; margin: 2em auto; padding: 0 1.2em; color: #222; line-height: 1.55; }
  h1 { border-bottom: 2px solid #2c3e50; padding-bottom: 0.3em; margin-bottom: 0.2em; }
  h2 { color: #2c3e50; margin-top: 1.8em; font-size: 1.15em; text-transform: uppercase; letter-spacing: 0.04em; }
  h3 { font-size: 1.0em; margin: 1.1em 0 0.3em; }
  .meta { color: #888; font-size: 0.85em; margin-bottom: 1.5em; }
  .muted { color: #888; font-style: italic; }
  .warn { background: #fff7e6; border-left: 5px solid #b8860b; border-radius: 6px; padding: 0.7em 1em; color: #8a6d00; }
  .status-section { margin: 0.6em 0; }
  .status-body { color: #444; font-size: 0.92em; white-space: pre-wrap; }
  .recommend { background: #eef6ee; border-left: 5px solid #2d7d2d; border-radius: 6px; padding: 1em 1.2em; margin: 1.2em 0; font-size: 1.05em; }
  .recommend .tag { display: block; font-size: 0.7em; text-transform: uppercase; letter-spacing: 0.08em; color: #2d7d2d; font-weight: 700; margin-bottom: 0.3em; }
  .option { border: 1px solid #e2e2e2; border-radius: 8px; padding: 0.9em 1.1em; margin: 0.7em 0; background: #fafafa; }
  .option.chosen-card { border-color: #2d7d2d; background: #f3faf3; }
  .opt-head { display: flex; align-items: center; gap: 0.6em; margin-bottom: 0.3em; }
  .opt-label { font-weight: 600; font-size: 1.02em; }
  .opt-desc { color: #555; font-size: 0.95em; }
  .badge { font-size: 0.68em; text-transform: uppercase; letter-spacing: 0.05em; padding: 0.15em 0.55em; border-radius: 10px; font-weight: 700; color: #fff; }
  .badge.rec { background: #2d7d2d; }
  .badge.chosen { background: #2c3e50; }
  table { width: 100%; border-collapse: collapse; margin: 0.8em 0; }
  th, td { text-align: left; padding: 0.55em 0.7em; border-bottom: 1px solid #eee; vertical-align: top; }
  th { background: #f0f0f0; font-weight: 600; font-size: 0.85em; text-transform: uppercase; letter-spacing: 0.03em; }
  td.aid { font-weight: 700; color: #2c3e50; white-space: nowrap; }
  .cost { font-weight: 700; text-transform: uppercase; font-size: 0.8em; }
  .pos { display: inline-block; color: #fff; padding: 0.15em 0.6em; border-radius: 4px; font-size: 0.8em; font-weight: 700; white-space: nowrap; }
  .resolution { color: #777; font-size: 0.88em; margin-top: 0.3em; font-style: italic; }
  .decision-form fieldset { border: 1px solid #ddd; border-radius: 8px; margin: 0.8em 0; padding: 0.8em 1em; }
  .decision-form legend { font-weight: 700; color: #2c3e50; padding: 0 0.4em; }
  .opt-radio { display: block; padding: 0.2em 0; }
  .assum { margin: 0.7em 0; padding-bottom: 0.6em; border-bottom: 1px solid #f0f0f0; }
  .assum-pos { margin: 0.3em 0; }
  .pos-radio { margin-right: 0.8em; white-space: nowrap; }
  .assum-note, .notes-label textarea { width: 100%; box-sizing: border-box; margin-top: 0.3em; }
  .submit-row { margin-top: 1em; display: flex; align-items: center; gap: 1em; }
  .decision-form button { background: #2d7d2d; color: #fff; border: 0; border-radius: 6px; padding: 0.5em 1.2em; font-size: 1em; cursor: pointer; }
  .result { font-weight: 700; }
  .footer { margin-top: 3em; padding-top: 1em; border-top: 1px solid #ddd; color: #aaa; font-size: 0.8em; }
"""


def render_dashboard(panes, interactive=False):
    """Pure render: turn a panes dict into the full HTML page. Reused verbatim by the ephemeral
    decision-server (interactive=True serves the act-from-page form). `panes` keys: phase,
    phase_name, generated, status (from load_status), brief (validated dict or None)."""
    phase = panes.get("phase", "?")
    phase_name = panes.get("phase_name", "")
    generated = panes.get("generated", "")
    mode = "act-from-page (served)" if interactive else "monitor (read-only, on-demand)"
    status_html = render_status(panes["status"])
    direction_html = render_direction(panes.get("brief"), interactive)
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Project Dashboard: Phase {esc(phase)}</title>
<style>{_CSS}</style>
</head>
<body>
<h1>Phase {esc(phase)} &mdash; {esc(phase_name)}</h1>
<div class="meta">Project-state dashboard &middot; generated {esc(generated)} &middot; {esc(mode)}</div>

<h2>Project status</h2>
{status_html}

<h2>Direction gate</h2>
{direction_html}

<div class="footer">Generated by generate-dashboard.py &middot; project-state dashboard (Phase 106). {"Submit drives the /dev-plan gate via the ephemeral decision-server." if interactive else "Render-only monitor; run a /dev-plan gate to act."}</div>
</body>
</html>"""


def _active_phase_line():
    """Best-effort orienting fallback for the phase header when no brief is present."""
    try:
        m = re.search(r"^Phase:\s*(.+)$", (ROOT / ".claude" / "rules" / "active-phase.md").read_text(), re.MULTILINE)
        return m.group(1).strip() if m else ""
    except OSError:
        return ""


def build_panes(state_path, brief_path):
    """Assemble the panes dict from the live files. Status degrades gracefully; the brief FAILS
    LOUD (ValueError) when present-but-malformed (caught in main -> stderr + exit 1)."""
    status = load_status(state_path)
    brief = None
    if Path(brief_path).exists():
        brief = load_brief(brief_path)  # validates; raises ValueError on malformed/missing-field
    if brief is not None:
        phase = brief.get("phase", "?")
        phase_name = brief.get("phase_name", "")
        generated = brief.get("generated", "")
    else:
        phase = _active_phase_line() or "?"
        phase_name = ""
        generated = ""
    return {"phase": phase, "phase_name": phase_name, "generated": generated, "status": status, "brief": brief}


def main():
    parser = argparse.ArgumentParser(description="Generate the project-state dashboard (render-only static page).")
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
              f"status-recognized: {panes['status']['recognized']}  brief: {panes['brief'] is not None}")
        print(f"Output (would write): {args.output}")
        return

    html = render_dashboard(panes, interactive=False)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html)
    print(f"Project-state dashboard written to {out}", file=sys.stderr)


if __name__ == "__main__":
    main()
