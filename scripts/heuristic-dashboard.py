#!/usr/bin/env python3
"""Heuristic evolution dashboard — reads wiki/heuristics/*.md and reports counter stats."""

import argparse
import glob
import os
import re
import sys


def parse_frontmatter(path):
    with open(path) as f:
        text = f.read()
    m = re.match(r'^---\n(.*?)\n---', text, re.DOTALL)
    if not m:
        return None
    fm = {}
    for line in m.group(1).splitlines():
        k_v = line.split(':', 1)
        if len(k_v) == 2:
            fm[k_v[0].strip()] = k_v[1].strip().strip('"')
    return fm


def main():
    parser = argparse.ArgumentParser(description='Heuristic evolution dashboard')
    parser.add_argument('--dir', default='wiki/heuristics',
                        help='Path to heuristics directory')
    args = parser.parse_args()

    if not os.path.isdir(args.dir):
        print(f'No heuristics directory at {args.dir}')
        sys.exit(0)

    files = sorted(glob.glob(os.path.join(args.dir, '*.md')))
    files = [f for f in files if not f.endswith('SCHEMA.md')]

    if not files:
        print('No heuristic articles found.')
        sys.exit(0)

    rows = []
    for path in files:
        fm = parse_frontmatter(path)
        if not fm or 'id' not in fm:
            continue
        hid = fm['id']
        helpful = int(fm.get('helpful', 0))
        harmful = int(fm.get('harmful', 0))
        total = helpful + harmful
        status = fm.get('status', 'unknown')
        if total == 0:
            ratio_str = 'unscored'
            health = '?'
        else:
            ratio = harmful / total
            ratio_str = f'{ratio:.0%}'
            if status == 'iron':
                health = '!' if ratio > 0.3 else 'ok'
            elif status == 'under-review':
                health = 'REVIEW'
            elif status == 'deprecated':
                health = 'DEPR'
            elif ratio > 0.3 and total >= 5:
                health = 'AT RISK'
            else:
                health = 'ok'
        rows.append((hid, status, helpful, harmful, total, ratio_str, health))

    print(f'\nHeuristic Evolution Dashboard ({len(rows)} heuristics)')
    print('=' * 72)
    print(f'{"ID":<12} {"Status":<13} {"Help":>4} {"Harm":>4} {"Total":>5} {"Ratio":>8} {"Health":>8}')
    print('-' * 72)
    for hid, status, helpful, harmful, total, ratio_str, health in rows:
        print(f'{hid:<12} {status:<13} {helpful:>4} {harmful:>4} {total:>5} {ratio_str:>8} {health:>8}')

    never_matched = [r for r in rows if r[4] == 0]
    if never_matched:
        print(f'\nNever matched ({len(never_matched)}):')
        for r in never_matched:
            print(f'  {r[0]} — consider rewriting trigger or verifying relevance')

    at_risk = [r for r in rows if r[6] in ('AT RISK', 'REVIEW', '!')]
    if at_risk:
        print(f'\nNeeds attention ({len(at_risk)}):')
        for r in at_risk:
            print(f'  {r[0]} ({r[1]}) — harm ratio {r[5]}')

    print()


if __name__ == '__main__':
    main()
