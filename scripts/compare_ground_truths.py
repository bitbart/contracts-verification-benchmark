#!/usr/bin/env python3
"""
compare_ground_truths.py — compare the 'truth' column between two versions.

Usage:
  python3 compare_ground_truths.py --contract lending-protocol --from v1 --to v4

Looks for:
  ../contracts/<contract>/ground-truth.csv
"""

import argparse
import sys
from pathlib import Path
from collections import defaultdict

def load_truths(csv_path):
    truths = defaultdict(dict)  # property -> {version: truth}
    versions = set()
    with open(csv_path, "r", encoding="utf-8", newline="") as f:
        for raw in f:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            if line.lower().startswith("property,version,truth"):
                continue  # header
            # take only the first 3 fields; footnotes may contain commas
            parts = line.split(",", 3)
            if len(parts) < 3:
                continue
            prop, ver, truth = parts[0].strip(), parts[1].strip(), parts[2].strip()
            if not prop or not ver or truth == "" or prop.lower() == "property":
                continue
            truths[prop][ver] = truth
            versions.add(ver)
    return truths, versions

def print_table(rows):
    if not rows:
        return
    cols = ["property", "from", "to"]
    widths = [len(c) for c in cols]
    for r in rows:
        for i, c in enumerate(cols):
            widths[i] = max(widths[i], len(str(r[c])))
    def fmt(vals):
        return "  " + "  |  ".join(str(vals[i]).ljust(widths[i]) for i in range(len(cols)))
    print(fmt(["property", "from", "to"]))
    print("  " + "-----+-".join("-" * w for w in widths))
    for r in rows:
        print(fmt([r["property"], r["from"], r["to"]]))

def main():
    ap = argparse.ArgumentParser(description="Compare ground truths for two versions (truth-only).")
    ap.add_argument("--contract", required=True, help="Name under ../contracts/<name>/")
    ap.add_argument("--from", dest="from_ver", required=True, help="Baseline version, e.g. v1")
    ap.add_argument("--to", dest="to_ver", required=True, help="Target version, e.g. v4")
    args = ap.parse_args()

    base = (Path(__file__).resolve().parent / ".." / "contracts" / args.contract).resolve()
    gt_path = base / "ground-truth.csv"
    if not gt_path.exists():
        sys.exit(f"Ground-truth not found: {gt_path}")

    truths, versions = load_truths(gt_path)

    for v in (args.from_ver, args.to_ver):
        if v not in versions:
            sys.exit(f"Version not found: {v}. Available: {', '.join(sorted(versions))}")

    changes = []
    for prop, vmap in sorted(truths.items()):
        if args.from_ver in vmap and args.to_ver in vmap:
            a, b = vmap[args.from_ver], vmap[args.to_ver]
            if a != b:
                changes.append({"property": prop, "from": a, "to": b})

    print(f"\nDiff of ground truths {args.from_ver} → {args.to_ver} [{args.contract}]")
    print(f"Changed properties: {len(changes)}\n")
    if changes:
        print("Changed truths:")
        print_table(changes)
    else:
        print("No truth changes.")

if __name__ == "__main__":
    main()
