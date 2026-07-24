import argparse
import os

def main(a):

    parser = argparse.ArgumentParser(description='')
    parser.add_argument('--contract', action='store', required=True, type=str,
                        help="contract to run the experiments")
    parser.add_argument('--version', action='store', required=False, type=str,
                        help="version of the contract over which to run the experiments (if not specified, runs over all versions)")
    parser.add_argument('--property', action='store', required=False, type=str,
                        help="property of the contract over which to run the experiments (if not specified, runs over all properties)")
    parser.add_argument('--timeout', action='store', required=False, default="600",
                        help="timeout for each verification task")
    parser.add_argument('--only_ground_truth', action='store_true', required=False, default=False, 
                        help="limit experiments to verification tasks which have a ground truth in ground-truth.csv")

    args = parser.parse_args(a)


    import run_certora

    args_certora = ["--contracts", f"./versions"]

    if args.property:
        args_certora += ["--specs", f"./certora/{args.property}.spec"]
    else:
        args_certora += ["--specs", "./certora/"]

    if args.version:
        args_certora += ["--version", args.version]

    if args.only_ground_truth:
        args_certora += ["--only_ground_truth"]

    # TODO
    #if args.timeout:
    #    args_certora += ["--timeout", args.timeout]

    args_certora += ["--output", "./certora"]

    print(args_certora)

    current_dir = os.getcwd()
    os.chdir(f"../contracts/{args.contract}")
    run_certora.main(args_certora)
    os.chdir(current_dir)

    # python3 run_certora_simple.py --contract bank --property assets-dec-onlyif-deposit --version 1

    # python3 run_certora.py --contracts ../contracts/bank/versions/ --output ../contracts/bank/certora --specs ../contracts/bank/certora/assets-dec-onlyif-deposit.spec --version 1

if __name__ == "__main__":
    import sys
    main(sys.argv[1:])
