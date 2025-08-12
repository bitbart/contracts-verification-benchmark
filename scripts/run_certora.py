"""
Operates on either a single file or every file within a directory.
"""
from tools.certora import run_all
from pathlib import Path
import argparse
import utils
import glob
import os

def main(args):
    parser = argparse.ArgumentParser()
    parser.add_argument(
            '--contracts',
            '-c',
            help='Contracts dir or contract file.',
            required=True)
    parser.add_argument(
            '--specs',
            '-s',
            help='CVL Specification dir or file.',
            required=True)
    parser.add_argument(  # build/
            '--output',
            '-o',
            help='Output directory.')
    parser.add_argument(
            '--version',
            '-v',
            help='Run experiments on this version only.')
    parser.add_argument(
            '--property',
            '-p',
            help='Run experiments on this property only.')
    args = parser.parse_args(args)

    contracts = Path(args.contracts)
    specs = Path(args.specs)

    # Get contracts paths
    contracts_paths = (
            glob.glob(f'{contracts}/*.sol')
            if os.path.isdir(contracts)
            else [str(contracts)])

    if args.version:
        contracts_paths = [c for c in contracts_paths if f"v{args.version}.sol" in c]

    # Get specs paths
    specs_paths = (
            glob.glob(f'{specs}/*.spec')
            if os.path.isdir(specs)
            else [str(specs)])

    if args.property:
        specs_paths = [s for s in specs_paths if args.property in s]

    if args.output:
        output_dir = Path(args.output)
        logs_dir = output_dir.joinpath('logs/')

        outcomes = run_all(contracts_paths, specs_paths, logs_dir)
        
        verification_tasks = []
        out_csv = [utils.OUT_HEADER]
        for id in outcomes.keys():
            p = id.split('_')[0]
            v = id.split('_')[1]
            out_csv.append([p, v, outcomes[id]])
            verification_tasks.append([p, v])

        existing_rows = utils.read_csv(output_dir.joinpath('out.csv'))
        for existing_row in existing_rows:
            existing_verification_task = existing_row[:2]
            if existing_verification_task in verification_tasks:
                continue
            if existing_verification_task == ['property','version']:
                continue
            out_csv.append(existing_row)      
            
        utils.write_csv(output_dir.joinpath('out.csv'), out_csv)
    else:
        run_all(contracts_paths, specs_paths)


if __name__ == '__main__':
        import sys
        main(sys.argv[1:])
