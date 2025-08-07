"""
Generates solcmc contracts from versions and properties files.
"""
from setup.instrumentation import instrument_contracts
from pathlib import Path
import argparse
import glob
import os

def main(args):
    parser = argparse.ArgumentParser()
    parser.add_argument(
            '--versions',
            '-v',
            help='Version file or dir path.',
            required=True)
    parser.add_argument(
            '--properties',
            '-p',
            help='Property file or dir path.',
            required=True)
    parser.add_argument(
            '--output',
            '-o',
            help='Output directory path.',)
    args = parser.parse_args(args)

    versions = Path(args.versions)
    properties = Path(args.properties)

    if args.output:
        Path(args.output).mkdir(parents=True, exist_ok=True)

    versions_paths = (
            glob.glob(f'{args.versions}/*v*.sol')
            if os.path.isdir(args.versions)
            else [args.versions])

    properties_paths = (
            glob.glob(f'{args.properties}/*.sol')
            if os.path.isdir(args.properties)
            else [args.properties])

    contracts = instrument_contracts(versions_paths, properties_paths)

    for filename in contracts.keys():
        if args.output:
            output = Path(args.output)
            with open(output.joinpath(filename), 'w+') as f:
                f.write(contracts[filename])
        else:
            print(contracts[filename])

if __name__ == '__main__':
        import sys
        main(sys.argv[1:])