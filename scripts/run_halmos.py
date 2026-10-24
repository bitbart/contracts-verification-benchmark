"""
CLI entry point to launch Halmos benchmark and record results into out.csv.
"""
from pathlib import Path
import argparse
import csv
import sys

import utils
from tools.halmos import run_all, parse_timeout_to_seconds

DEFAULT_TIMEOUT = '10m'


def read_gt_keys(gt_path):
    """Return the set of (property, version) pairs listed in a ground-truth file."""
    keys = set()
    if gt_path.exists():
        with open(gt_path, 'r', newline='') as f:
            reader = csv.reader(f)
            next(reader, None)  # skip header
            for row in reader:
                if row and len(row) >= 2:
                    keys.add((row[0], row[1]))
    return keys


def merge_rows(current_results, existing_rows, valid_keys):
    """
    Merge the results of the current run into existing rows (header excluded):
    re-run tasks are updated (or dropped on ERR), new tasks are added,
    untouched rows are kept, rows not in valid_keys are dropped.
    """
    merged = []
    seen = set()
    for row in existing_rows:
        if not row or len(row) < 2:
            continue
        key = (row[0], row[1])
        if key not in valid_keys:
            continue
        if key in current_results:
            res = current_results[key]
            if str(res).upper() not in ["ERR"]:
                merged.append([row[0], row[1], res])
            seen.add(key)
        else:
            merged.append(row)

    for (p, v), res in current_results.items():
        if (p, v) not in seen and (p, v) in valid_keys and str(res).upper() not in ["ERR"]:
            merged.append([p, v, res])

    return merged


def main(args):
    parser = argparse.ArgumentParser()
    parser.add_argument('--halmos-dir', '-hd', help='Halmos working directory.', required=False)
    parser.add_argument('--contracts', '-c', help='Contracts file or directory.', required=True)
    parser.add_argument('--output', '-o', help='Output directory.', required=False)
    parser.add_argument('--timeout', '-t', help='Timeout time.', required=False)
    parser.add_argument('--version', '-v', help='Run on this version only (e.g. 1 or v1).', required=False)
    parser.add_argument('--property', '-p', help='Run on this property only.', required=False)
    args = parser.parse_args(args)

    
    output_parents = []
    halmos_dir_candidates = [Path("./halmos")]
    if args.output:
        output = Path(args.output).resolve()
        output_parents = [output.parent.parent, output.parent.parent.parent]
        halmos_dir_candidates += [output.parent / "contracts", output.parent.parent / "halmos"]

    if args.halmos_dir:
        halmos_dir = Path(args.halmos_dir)
    else:
        halmos_dir = next((d for d in halmos_dir_candidates if d.is_dir()), halmos_dir_candidates[0])

    if args.version and not args.version.startswith('v'):
        args.version = f"v{args.version}"

    timeout = args.timeout if args.timeout else DEFAULT_TIMEOUT
    timeout_seconds = parse_timeout_to_seconds(timeout)

    candidates = [d / "ground-truth.csv" for d in output_parents]
    candidates += [Path("../ground-truth.csv"), Path("./ground-truth.csv")]
    gt_path = next((p for p in candidates if p.is_file()), candidates[-1])

    # Read ground-truth: set of valid (property, version) pairs
    gt_keys = read_gt_keys(gt_path)

    tasks = []

    if args.property and args.version:
        # Explicit pair: run only if present in ground-truth
        if (args.property, args.version) in gt_keys:
            tasks.append((args.property, args.version))
        else:
            print(f"Warning: ({args.property}, {args.version}) not in ground-truth, skipping.",
                  file=sys.stderr)

    elif args.property:
        # Only property: run only versions listed in ground-truth for it
        for (p, v) in sorted(gt_keys):
            if p == args.property:
                tasks.append((p, v))
        if not tasks:
            print(f"Warning: no ground-truth entries for property '{args.property}'.",
                  file=sys.stderr)

    else:
        # No filter: run all ground-truth pairs (optionally restricted by version)
        for (p, v) in sorted(gt_keys):
            if args.version and v != args.version:
                continue
            tasks.append((p, v))

    # Without an output dir: run only, logs and results are printed
    if not args.output:
        run_all(tasks, timeout_seconds, halmos_dir=halmos_dir)
        return

    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)
    logs_dir = output_dir.joinpath('logs')
    logs_dir.mkdir(parents=True, exist_ok=True)

    # Execute all tasks
    current_results = run_all(tasks, timeout_seconds, logs_dir, halmos_dir)

    # Write out.csv: merged with the previous runs (ERR entries excluded)
    out_csv_path = output_dir.joinpath('out.csv')
    existing_out_rows = utils.read_csv(out_csv_path)[1:]
    out_csv = [utils.OUT_HEADER] + merge_rows(current_results, existing_out_rows, gt_keys)
    utils.write_csv(out_csv_path, out_csv)

    history_path = (output_dir / ".." / ".." / ".." / "halmos.csv").resolve()


    history_gt_keys = read_gt_keys(history_path.parent / "ground-truth.csv")
    for case_gt in history_path.parent.glob("*/ground-truth.csv"):
        history_gt_keys |= read_gt_keys(case_gt)

    all_current = dict(current_results)
    seen = set()
    existing_rows = []

    if history_path.exists():
        try:
            with open(history_path, 'r', newline='') as f:
                reader = csv.reader(f)
                next(reader, None)  # skip header
                for row in reader:
                    if row and len(row) >= 2:
                        key = (row[0], row[1])

                        # Drop rows not present in ground-truth
                        if key not in history_gt_keys:
                            continue

                        if key in all_current:
                            res = all_current[key]
                            if str(res).upper() not in ["ERR"]:
                                existing_rows.append([row[0], row[1], res])
                            # On ERR (e.g. no test file for this version): drop the old row
                            seen.add(key)
                        else:
                            # Untouched row: keep as-is
                            existing_rows.append(row)
        except Exception as e:
            print(f"Warning: could not read history {history_path}: {e}", file=sys.stderr)

    # Add new rows from current run (only if in ground-truth)
    for (p, v), res in all_current.items():
        if (p, v) not in seen and str(res).upper() not in ["ERR"]:
            if (p, v) in gt_keys:
                existing_rows.append([p, v, res])

    # Sort alphabetically by (property, version)
    existing_rows.sort(key=lambda r: (r[0], r[1]))

    # Write back the merged history
    with open(history_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(utils.OUT_HEADER)
        writer.writerows(existing_rows)

if __name__ == '__main__':
    main(sys.argv[1:])