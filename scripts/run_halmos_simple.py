import argparse
import run_halmos

def main():
    parser = argparse.ArgumentParser(description='Halmos benchmark orchestrator')
    parser.add_argument('--contract', action='store', required=True, type=str,
                        help="contract to run the experiments")
    parser.add_argument('--version', action='store', required=False, type=str,
                        help="version of the contract over which to run the experiments")
    parser.add_argument('--property', action='store', required=False, type=str,
                        help="property of the contract over which to run the experiments")

    args = parser.parse_args()

    args_halmos = [
        "--contracts", args.contract,
        "--output", "./build/halmos"
    ]

    if args.version:
        args_halmos += ["--version", args.version]

    if args.property:
        args_halmos += ["--property", args.property]

    run_halmos.main(args_halmos)

if __name__ == '__main__':
    main()