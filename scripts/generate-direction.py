#!/usr/bin/env python3
"""Generate a render-only HTML "direction dashboard" for a dev-wiki phase.

Renders the /dev-plan DIRECTION GATE as a static, scannable page — recommendation,
option cards (recommended highlighted), cost-sorted assumptions + positions, and
orienting context — from a structured direction brief, so the maintainer reviews
design directions visually at human pace, then answers the gate in-session.

4th member of the docs/ HTML-generator family (generate-report / generate-workflow /
generate-delivery-report); self-contained, matching the house style. Render-only —
no server, no browser->session round-trip.

Usage:
    python3 scripts/generate-direction.py [--brief PATH] [--output PATH] [--dry-run]

Defaults: --brief .dev-wiki/direction-brief.json, --output docs/direction.html
"""

import argparse
import html
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WIKI = ROOT / ".dev-wiki"

POSITION_COLOR = {"accept": "#2d7d2d", "reject": "#c0392b", "don't-know": "#b8860b"}
COST_COLOR = {"high": "#c0392b", "medium": "#b8860b", "low": "#666"}


def esc(s):
    # stdlib escaper (quote=True) — also escapes " and ' so brief strings are safe in any
    # attribute context, not just element text. Review-gate LOW (Phase 99), defense-in-depth.
    return html.escape(str(s))


def validate_brief(b):
    """Reject a brief missing required fields. Controls-first (HEU-012): the generator
    MUST fail loud rather than render a page from garbage input (clean-on-seed = dead)."""
    errors = []
    if "phase" not in b:
        errors.append("missing required field: phase")
    if not b.get("recommendation"):
        errors.append("missing/empty required field: recommendation")
    opts = b.get("options")
    if not isinstance(opts, list) or not opts:
        errors.append("missing/empty required field: options (non-empty list)")
    else:
        for i, o in enumerate(opts):
            if not isinstance(o, dict) or not o.get("label"):
                errors.append(f"option[{i}] missing label")
            elif isinstance(o, dict):
                # reasoning/consequences are OPTIONAL (Phase 107) but, when present, must be strings —
                # a non-string would render as garbage, so fail loud rather than silently.
                for fld in ("reasoning", "consequences"):
                    if fld in o and not isinstance(o[fld], str):
                        errors.append(f"option[{i}] {fld} must be a string")
    asn = b.get("assumptions")
    if not isinstance(asn, list) or not asn:
        errors.append("missing/empty required field: assumptions (non-empty list)")
    else:
        for i, a in enumerate(asn):
            if not isinstance(a, dict) or not a.get("id") or not a.get("text"):
                errors.append(f"assumption[{i}] missing id/text")
    if errors:
        raise ValueError("invalid direction brief:\n  - " + "\n  - ".join(errors))


def load_brief(path):
    """Read, parse, and validate the direction brief. Raises ValueError (caught in main,
    printed to stderr with a non-zero exit) on malformed JSON or a missing required field."""
    try:
        data = json.loads(Path(path).read_text())
    except json.JSONDecodeError as e:
        raise ValueError(f"malformed JSON in brief {path}: {e}")
    validate_brief(data)
    return data


def get_active_phase_line():
    """Best-effort orienting context from the live dev-wiki; never fatal."""
    ap = ROOT / ".claude" / "rules" / "active-phase.md"
    try:
        m = re.search(r"^Phase:\s*(.+)$", ap.read_text(), re.MULTILINE)
        return m.group(1).strip() if m else None
    except OSError:
        return None


def _phase_num(val):
    """Leading integer of a phase value ('107 — Foo' or 107), or None if unparseable."""
    m = re.match(r"\s*(\d+)", str(val))
    return int(m.group(1)) if m else None


def is_stale(brief, active_phase):
    """True iff the brief's phase differs from the live active phase (Phase 107 stale-brief guard).
    FAIL-OPEN: if either phase number is unparseable, return False — the guard never fabricates a
    staleness it can't prove; a brief is only 'stale' when both phases parse AND differ. Shared by
    the render layer (loud banner / no decidable form) and the served decision path."""
    bp = _phase_num(brief.get("phase"))
    ap = _phase_num(active_phase)
    if bp is None or ap is None:
        return False
    return bp != ap


def render_options(options):
    cards = ""
    for o in options:
        recommended = bool(o.get("recommended"))
        chosen = bool(o.get("chosen"))
        badges = ""
        if recommended:
            badges += '<span class="badge rec">Recommended</span>'
        if chosen:
            badges += '<span class="badge chosen">Chosen</span>'
        cls = "option chosen-card" if chosen else "option"
        # reasoning (the case FOR this option) + consequences (what it commits to / forecloses),
        # rendered INSIDE this option's own card so the trade-off is comparable per-option — not a
        # field dump elsewhere on the page (Phase 107). Both OPTIONAL: a legacy brief omits them and
        # the card renders exactly as before (backward-compatible).
        extra = ""
        if o.get("reasoning"):
            extra += (f'<div class="opt-reasoning"><span class="opt-tag">Reasoning</span>'
                      f'{esc(o.get("reasoning", ""))}</div>')
        if o.get("consequences"):
            extra += (f'<div class="opt-consequences"><span class="opt-tag">Consequences</span>'
                      f'{esc(o.get("consequences", ""))}</div>')
        cards += (
            f'<div class="{cls}">'
            f'<div class="opt-head"><span class="opt-label">{esc(o.get("label", ""))}</span>{badges}</div>'
            f'<div class="opt-desc">{esc(o.get("description", ""))}</div>'
            f"{extra}"
            f"</div>\n"
        )
    return cards


def render_assumptions(assumptions):
    rows = ""
    for a in assumptions:
        pos = a.get("position", "")
        pcolor = POSITION_COLOR.get(pos, "#333")
        cost = a.get("cost", "")
        ccolor = COST_COLOR.get(cost, "#666")
        resolution = a.get("resolution", "")
        res_html = f'<div class="resolution">{esc(resolution)}</div>' if resolution else ""
        rows += (
            "<tr>"
            f'<td class="aid">{esc(a.get("id", ""))}</td>'
            f'<td><span class="cost" style="color:{ccolor}">{esc(cost)}</span></td>'
            f'<td>{esc(a.get("text", ""))}{res_html}</td>'
            f'<td><span class="pos" style="background:{pcolor}">{esc(pos)}</span></td>'
            "</tr>\n"
        )
    return rows


def generate_html(brief):
    phase = brief.get("phase", "?")
    phase_name = brief.get("phase_name", "")
    generated = brief.get("generated", "")
    recommendation = brief.get("recommendation", "")
    objective = brief.get("objective", "")
    options = brief.get("options", [])
    assumptions = brief.get("assumptions", [])
    context = brief.get("context", {}) or {}

    active_phase = context.get("active_phase") or get_active_phase_line() or ""
    open_decisions = context.get("open_decisions", []) or []
    decisions_html = "".join(f"<li>{esc(d)}</li>\n" for d in open_decisions) or "<li><em>none recorded</em></li>"

    objective_html = f'<p class="objective">{esc(objective)}</p>' if objective else ""

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Direction: Phase {esc(phase)}</title>
<style>
  body {{ font-family: -apple-system, system-ui, sans-serif; max-width: 960px; margin: 2em auto; padding: 0 1.2em; color: #222; line-height: 1.55; }}
  h1 {{ border-bottom: 2px solid #2c3e50; padding-bottom: 0.3em; margin-bottom: 0.2em; }}
  h2 {{ color: #2c3e50; margin-top: 1.8em; font-size: 1.15em; text-transform: uppercase; letter-spacing: 0.04em; }}
  .meta {{ color: #888; font-size: 0.85em; margin-bottom: 1.5em; }}
  .objective {{ color: #555; }}
  .recommend {{ background: #eef6ee; border-left: 5px solid #2d7d2d; border-radius: 6px; padding: 1em 1.2em; margin: 1.2em 0; font-size: 1.05em; }}
  .recommend .tag {{ display: block; font-size: 0.7em; text-transform: uppercase; letter-spacing: 0.08em; color: #2d7d2d; font-weight: 700; margin-bottom: 0.3em; }}
  .option {{ border: 1px solid #e2e2e2; border-radius: 8px; padding: 0.9em 1.1em; margin: 0.7em 0; background: #fafafa; }}
  .option.chosen-card {{ border-color: #2d7d2d; background: #f3faf3; }}
  .opt-head {{ display: flex; align-items: center; gap: 0.6em; margin-bottom: 0.3em; }}
  .opt-label {{ font-weight: 600; font-size: 1.02em; }}
  .opt-desc {{ color: #555; font-size: 0.95em; }}
  .opt-reasoning, .opt-consequences {{ font-size: 0.92em; margin-top: 0.5em; padding-left: 0.7em; border-left: 3px solid #d8d8d8; }}
  .opt-reasoning {{ border-left-color: #2d7d2d; color: #2c4a2c; }}
  .opt-consequences {{ border-left-color: #b8860b; color: #5a4a1a; }}
  .opt-tag {{ display: block; font-size: 0.68em; text-transform: uppercase; letter-spacing: 0.06em; font-weight: 700; opacity: 0.75; }}
  .badge {{ font-size: 0.68em; text-transform: uppercase; letter-spacing: 0.05em; padding: 0.15em 0.55em; border-radius: 10px; font-weight: 700; color: #fff; }}
  .badge.rec {{ background: #2d7d2d; }}
  .badge.chosen {{ background: #2c3e50; }}
  table {{ width: 100%; border-collapse: collapse; margin: 0.8em 0; }}
  th, td {{ text-align: left; padding: 0.55em 0.7em; border-bottom: 1px solid #eee; vertical-align: top; }}
  th {{ background: #f0f0f0; font-weight: 600; font-size: 0.85em; text-transform: uppercase; letter-spacing: 0.03em; }}
  td.aid {{ font-weight: 700; color: #2c3e50; white-space: nowrap; }}
  .cost {{ font-weight: 700; text-transform: uppercase; font-size: 0.8em; }}
  .pos {{ display: inline-block; color: #fff; padding: 0.15em 0.6em; border-radius: 4px; font-size: 0.8em; font-weight: 700; white-space: nowrap; }}
  .resolution {{ color: #777; font-size: 0.88em; margin-top: 0.3em; font-style: italic; }}
  .context {{ background: #f8f9fa; border-radius: 8px; padding: 1em 1.2em; }}
  ul {{ padding-left: 1.3em; margin: 0.4em 0; }}
  .footer {{ margin-top: 3em; padding-top: 1em; border-top: 1px solid #ddd; color: #aaa; font-size: 0.8em; }}
</style>
</head>
<body>
<h1>Phase {esc(phase)} &mdash; {esc(phase_name)}</h1>
<div class="meta">Direction gate &middot; generated {esc(generated)} &middot; render-only</div>

{objective_html}

<div class="recommend"><span class="tag">Recommendation</span>{esc(recommendation)}</div>

<h2>Options</h2>
{render_options(options)}

<h2>Assumptions (cost-sorted) &amp; positions</h2>
<table>
<tr><th>ID</th><th>Cost</th><th>Assumption</th><th>Position</th></tr>
{render_assumptions(assumptions)}
</table>

<h2>Orienting context</h2>
<div class="context">
  <p><strong>Active phase:</strong> {esc(active_phase) or "&mdash;"}</p>
  <p><strong>Open decisions:</strong></p>
  <ul>
  {decisions_html}
  </ul>
</div>

<div class="footer">Generated by generate-direction.py &middot; render-only direction dashboard (Phase 99). Answer the gate in-session.</div>
</body>
</html>"""


def main():
    parser = argparse.ArgumentParser(description="Generate a render-only direction dashboard for a dev-wiki phase.")
    parser.add_argument("--brief", default=str(WIKI / "direction-brief.json"), help="Direction brief JSON path")
    parser.add_argument("--output", default=str(ROOT / "docs" / "direction.html"), help="Output HTML path")
    parser.add_argument("--dry-run", action="store_true", help="Parse the brief and report without writing HTML")
    args = parser.parse_args()

    brief_path = Path(args.brief)
    if not brief_path.exists():
        print(f"Error: direction brief not found: {brief_path}", file=sys.stderr)
        sys.exit(1)

    try:
        brief = load_brief(brief_path)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    if args.dry_run:
        print(f"Phase: {brief.get('phase')} - {brief.get('phase_name', '')}")
        print(f"Options: {len(brief.get('options', []))}  Assumptions: {len(brief.get('assumptions', []))}")
        print(f"Output (would write): {args.output}")
        return

    html = generate_html(brief)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html)
    print(f"Direction dashboard written to {out}", file=sys.stderr)


if __name__ == "__main__":
    main()
