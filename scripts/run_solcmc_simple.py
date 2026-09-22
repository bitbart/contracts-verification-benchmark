import argparse
import builder, run_solcmc

def main():
    parser = argparse.ArgumentParser(description="")
    parser.add_argument("--contract", action="store", required=True, type=str,
                        help="contract to run the experiments")
    parser.add_argument("--version", action="store", required=False, type=str,
                        help="version of the contract over which to run the experiments (if not specified, runs over all versions)")
    parser.add_argument("--property", action="store", required=False, type=str,
                        help="property of the contract over which to run the experiments (if not specified, runs over all properties)")
    parser.add_argument("--solver", action="store", required=False, type=str,
                        help="[z3, eld] (if not specified, runs with all solvers)")
    parser.add_argument("--timeout", action="store", required=False, default="600",
                        help="timeout for each verification task")

    args = parser.parse_args()

    builder.main(["--versions", f"../contracts/{args.contract}/versions", 
                  "--properties", f"../contracts/{args.contract}/solcmc",
                  "--output", f"../contracts/{args.contract}/solcmc/build/contracts"])

    args_solcmc = ["--contracts", f"../contracts/{args.contract}/solcmc/build/contracts"]

    if args.version:
        args_solcmc += ["--version", args.version]

    if args.property:
        args_solcmc += ["--property", args.property]

    if args.timeout:
        args_solcmc += ["--timeout", args.timeout]

    if args.solver:
        args_solcmc += ["--solver", args.solver]
        args_solcmc += ["--output", f"../contracts/{args.contract}/solcmc/build/{args.solver}"]
        run_solcmc.main(args_solcmc)
    else:
        for solver in ["z3","eld"]:
            print(f"\nUsing {solver} as backend SMT-solver:")
            args_solcmc_solv = list(args_solcmc)
            args_solcmc_solv += ["--solver", solver]
            args_solcmc_solv += ["--output", f"../contracts/{args.contract}/solcmc/build/{solver}"]
            run_solcmc.main(args_solcmc_solv)

if __name__ == "__main__":
    main()
