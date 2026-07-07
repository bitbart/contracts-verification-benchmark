"""
Script to launch Halmos within the benchmark framework and format the results for the Confusion Matrix.
"""
from pathlib import Path
import argparse
import subprocess
import csv
import sys
import re
import utils

def run_halmos_for_task(p, v, halmos_dir, output_dir):
    """
    Executes Halmos for a specific property and version, then parses the text output.
    Saves dedicated execution log files inside the build artifacts directory.
    """
    target_test = f"check_{p.replace('-', '_')}"
    print(f"Running Halmos verification for property: '{p}', version: '{v}'...")
    
    try:
        # Execute Halmos capturing both stdout and stderr
        halmos_res = subprocess.run(["halmos"], cwd=halmos_dir, capture_output=True, text=True)
        output = halmos_res.stdout + halmos_res.stderr
        
        logs_dir = Path(output_dir).joinpath("logs")
        logs_dir.mkdir(parents=True, exist_ok=True)
        log_filename = f"{v}_{p}.log"
        utils.write_log(logs_dir.joinpath(log_filename), output)
        # ---------------------------------------------------
        
        # Strip ANSI escape color codes from the terminal output to get clean text
        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
        clean_output = ansi_escape.sub('', output)
        
        # --- UNIVERSAL CASE-INSENSITIVE REGEX PARSING ---
        pass_pattern = rf"\[PASS\]\s+{target_test}\s*\(.*?\)"
        fail_pattern = rf"\[FAIL\]\s+{target_test}\s*\(.*?\)"
        
        if re.search(pass_pattern, clean_output, re.IGNORECASE):
            return utils.STRONG_POSITIVE  # Maps to 'P!' (Property holds / No Bug)
        elif re.search(fail_pattern, clean_output, re.IGNORECASE):
            return utils.STRONG_NEGATIVE  # Maps to 'N!' (Property violated / Bug Detected)
        else:
            if target_test.lower() in clean_output.lower():
                if "pass" in clean_output.lower() and "fail" not in clean_output.lower():
                    return utils.STRONG_POSITIVE
                elif "fail" in clean_output.lower():
                    return utils.STRONG_NEGATIVE
            return utils.UNKNOWN
        
    except Exception as e:
        print(f"Error during Halmos execution for {p}: {e}")
        return utils.ERROR                # Maps to 'ERR'
    
def main(args_list=None):
    parser = argparse.ArgumentParser()
    parser.add_argument('--contracts', '-c', help='Contracts file or directory.', required=True)
    parser.add_argument('--output', '-o', help='Output directory.', required=True)
    parser.add_argument('--version', '-v', help='Run on this version only.', required=False)
    parser.add_argument('--property', '-p', help='Run on this property only.', required=False)
    
    if args_list is not None:
        args = parser.parse_args(args_list)
    else:
        args = parser.parse_args()

    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)
    halmos_dir = Path("./halmos")
    
    tasks = []
    
    if args.property:
        v = args.version if args.version else 'v1'
        tasks.append((args.property, v))
    else:
        gt_path = Path("./ground-truth.csv")
        if gt_path.exists():
            with open(gt_path, 'r') as f:
                reader = csv.reader(f)
                next(reader)  # Skip CSV header
                for row in reader:
                    if row and len(row) >= 2:
                        tasks.append((row[0], row[1]))
        else:
            tasks.append(("unknown-property", "v1"))

    current_results = {}
    for p, v in tasks:
        # Pass both directories: halmos_dir for context execution, output_dir for clean log writing
        res = run_halmos_for_task(p, v, halmos_dir, output_dir)
        current_results[(p, v)] = res

    out_csv_path = output_dir.joinpath('out.csv')
    existing_rows = []
    if out_csv_path.exists():
        try:
            with open(out_csv_path, 'r') as f:
                reader = csv.reader(f)
                next(reader)
                for row in reader:
                    if row:
                        if (row[0], row[1]) not in current_results:
                            existing_rows.append(row)
        except Exception:
            pass

    out_csv = [utils.OUT_HEADER] + existing_rows
    for (p, v), res in current_results.items():
        out_csv.append([p, v, res])

    with open(out_csv_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerows(out_csv)
        
    for (p, v), res in current_results.items():
        print(f"Halmos result appended for {p} ({v}): {res}")

if __name__ == '__main__':
    main()