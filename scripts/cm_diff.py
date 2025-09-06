#!/usr/bin/env python3
"""
cm_diff.py — diff confusion-matrix labels between two versions.

Usage:
  python3 cm_diff.py --contract lending-protocol --from v1 --to v4

Looks for:
  ../contracts/<contract>/ground-truth.csv
  ../contracts/<contract>/certora.csv

Requires:
  cm_gen.py in the same directory as this script.
"""

import argparse
import csv
import sys
import subprocess
from collections import defaultdict
from pathlib import Path

def run_cm_gen(cm_path: Path, gt_path: Path, res_path: Path):
    cmd = [sys.executable, str(cm_path), "-g", str(gt_path), "-r", str(res_path)]
    proc = subprocess.run(cmd, check=True, capture_output=True, text=True)
    return proc.stdout.splitlines()

def parse_cm_lines(lines):
    # Accept optional header; parse rows like: property,version,label
    reader = csv.reader(lines)
    data = []
    for row in reader:
        if not row or len(row) < 3:
            continue
        if row[0].strip().lower() == "property":
            continue
        prop, ver, lab = row[0].strip(), row[1].strip(), row[2].strip()
        if prop and ver and lab:
            data.append((prop, ver, lab))
    return data

def print_table(rows):
    if not rows:
        return
    cols = ["property", "from", "to", "transition"]
    widths = [len(c) for c in cols]
    for r in rows:
        widths[0] = max(widths[0], len(r["property"]))
        widths[1] = max(widths[1], len(r["from"]))
        widths[2] = max(widths[2], len(r["to"]))
        widths[3] = max(widths[3], len(r["transition"]))
    def fmt(vals):
        return "  " + "  |  ".join(str(vals[i]).ljust(widths[i]) for i in range(4))
    print(fmt(cols))
    print("  " + "-----+-".join("-" * w for w in widths))
    for r in rows:
        print(fmt([r["property"], r["from"], r["to"], r["transition"]]))

def main():
    ap = argparse.ArgumentParser(description="Diff confusion-matrix outputs for two versions.")
    ap.add_argument("--contract", required=True, help="Name under ../contracts/<name>/")
    ap.add_argument("--from", dest="from_ver", required=True, help="Baseline version, e.g. v1")
    ap.add_argument("--to", dest="to_ver", required=True, help="Target version, e.g. v4")
    args = ap.parse_args()

    script_dir = Path(__file__).resolve().parent
    cm_path = script_dir / "cm_gen.py"
    if not cm_path.exists():
        sys.exit(f"cm_gen.py not found: {cm_path}")

    base = (script_dir / ".." / "contracts" / args.contract).resolve()
    gt_path = base / "ground-truth.csv"
    res_path = base / "certora.csv"
    if not gt_path.exists():
        sys.exit(f"Missing ground-truth.csv at: {gt_path}")
    if not res_path.exists():
        sys.exit(f"Missing certora.csv at: {res_path}")

    lines = run_cm_gen(cm_path, gt_path, res_path)
    entries = parse_cm_lines(lines)

    # property -> {version: label}
    by_prop = defaultdict(dict)
    versions = set()
    for prop, ver, lab in entries:
        by_prop[prop][ver] = lab
        versions.add(ver)

    for v in (args.from_ver, args.to_ver):
        if v not in versions:
            sys.exit(f"Version not found: {v}. Available: {', '.join(sorted(versions))}")

    changes = []
    for prop, vmap in sorted(by_prop.items()):
        if args.from_ver in vmap and args.to_ver in vmap:
            a, b = vmap[args.from_ver], vmap[args.to_ver]
            if a != b:
                changes.append({"property": prop, "from": a, "to": b, "transition": f"{a}→{b}"})

    print(f"\nChanged labels: {args.from_ver} → {args.to_ver} [{args.contract}]")
    print(f"Total changes: {len(changes)}\n")
    if changes:
        print_table(changes)
    else:
        print("No label changes.")

if __name__ == "__main__":
    main()
