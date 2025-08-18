# An open benchmark for evaluating smart contracts verification tools

This is an open project to construct a benchmark of Solidity contracts for evaluating and comparing formal verification tools.

The benchmark currently comprises 323 verification tasks, which have been used to compare two leading verification tools, SolCMC and Certora, and to evaluate their completeness, soundness and expressiveness limitations.

Details on the construction of the benchmark and on the comparison between SolCMC and Certora are available in the following research paper:
- M. Bartoletti, F. Fioravanti, G. Matricardi, R. Pettinau and F. Sainas. [Towards Benchmarking of Solidity verification tools](https://arxiv.org/abs/2402.10750). In [FMBC 2024](https://fmbc.gitlab.io/2024/)

## Contracts

> We are currently updating the contracts to the standard described in the "[extending the benchmark](#extending-the-benchmark)" section. Up-to-date contracts are marked with :white_check_mark:.

The benchmark currently comprises several versions (correct or bugged) of the following use cases:
- [Call Wrapper](contracts/call-wrapper/) 
- [Bet (tokenless)](contracts/zerotoken_bet/)
- [Deposit (ETH)](contracts/deposit_eth/) 
- [Deposit (ERC20)](contracts/deposit_erc20/)
- [Bank (tokenless)](contracts/zerotoken_bank/)
- [Bank (ETH)](contracts/bank/) :white_check_mark: 
- [Escrow](contracts/escrow/) 
- [Vault](contracts/vault/) :white_check_mark:
- [Price Bet](contracts/price-bet) :white_check_mark:
- [Crowdfund](contracts/crowdfund/) 
- [Hash Timed Locked Contract](contracts/htlc/) 
- [Vesting Wallet](contracts/vesting_wallet/) 
- [Lottery](contracts/lottery/)
- [Constant-product AMM](contracts/tinyamm/)
- [Lending Protocol](contracts/lending-protocol) :white_check_mark:
- [Payment Splitter](contracts/payment_splitter/)
- [Social Recovery Wallet](contracts/social_recovery_wallet/)


## Verification tools

Currently the benchmark supports the following verification tools:
- [SolCMC](https://verify.inf.usi.ch/publications/2022/solcmc-solidity-compiler%E2%80%99s-model-checker)
- [Certora](https://www.certora.com/)

## Evaluating a verification tool

The repo contains a set of use cases: each use case is associated with a set of Solidity implementations (possibly, containing bugs), and a set of properties against which to assess verification tools.
Here we are also interested in properties that go beyond the capabilities of the current tools, hoping that they can be of inspiration for more precise verification techniques.

For each use case, we evaluate the performance of a verification tool
as a matrix, where columns represent different contract properties, and
rows represent different implementations of the use case.
For each entry of the matrix, we summarize the output of the tool as follows:

| Symbol | Meaning                                                        |
| ------ | -------                                                        |
| TP     | True Positive  (property holds, verification succeeds)         |
| TN     | True Negative  (property does not hold, verification fails)    |
| FP     | False Positive (property does not hold, verification succeeds) |
| FN     | False Negative (property holds, verification fails)            |
| UNK    | Timeout / Memory exhaustion                                    |
| ND     | Property not definable with the tool                           |

Additionally, we mark with ! the classifications TP,TN,FP,FN, when the verification tool 
guarantees the correctness of the output. 
Following our [methodological notes](methodology/), we map the outputs of the 
verification tools according to the following table:

| Suffix  | SolCMC output           | Certora output |
|---------|-------------------------|----------------|
| P       |                         | Satisfy green  |
| P!      | Property is valid       | Assert green   |
| N       | Property might be false | Assert red     |
| N!      | Property is false       | Satisfy red    |

### Computing scores
To compute scores for each verification tool, navigate to the
[`contracts/`](contracts/) directory and execute the following command in your
terminal:
```
$ make
or
$ make scores
```
This commands will generate a `.csv` file where each tool is represented by a
row, displaying the count of different outcomes and the total score of the
tool. Please ensure that you have previously run experiments in the
corresponding usecase directories, as this process relies on experiments
results.

## Extending the benchmark

In the [`contracts/`](contracts/) directory, run the following command to initialize a new use case:

```
$ make init name=<usecase-name>
```
This command creates a new directory and provides the template to start your work.

### Use case directory structure

Each use case directory must include the following files:
- `skeleton.json`
- `ground-truth.csv`
- `versions` directory
- `Makefile`
- A directory for every verification tool used

Find a minimal example in [`contracts/template/`](contracts/template) directory.

#### skeleton.json

This file stores the use case's **name**, **credits**, **specification** and **properties**
defined in natural language:
```
{
    "name": "Simple Transfer",
    "credits": "[Author](https://www.author.com/simple_transfer)"   // optional
    "specification": "The contract has an initial balance...",
    "properties": {
        "sent_a": "the overall sent amount does not exceed the initial deposit.",
        ... 
    }
}
```
You can store specifications in a separate file, use the following syntax to
indicate the path:

```
"specification": "file:<relative_path>",
```
Here, the file path is relative to the path of the use case (e.g.
`simple_transfer/spec.md` would be `file:spec.md`).

#### ground-truth.csv

This file defines the ground truth for the corresponding use case. Lines of the
csv have the form:
```
property,version,sat,footnote
```
where `sat` is 1 when the property holds on the given version, and 0 when it
does not hold. The ground truth is established manually and, in some cases,
confirmed by the verification tools. Furthermore, there is the option to append
footnotes, which will be displayed in the readme file of the use case.

#### Versions Directory

The `versions/` directory contains various Solidity variants of the use case
contract, with version definitions in natural language written using the
NatSpec format and the `@custom:version` tag:
```
/// @custom:version <version definition>.
```

#### Makefile

The Makefile defines the following commands:
1. `make plain`: generates the README without experiment results. It utilizes `skeleton.json`, `ground-truth.csv` and version files from `versions/`.
1. `make solcmc`: runs the SolCMC experiments. By default, the timeout is set to 10 minutes. Use `make solcmc to=<int>` to set a different timeout for each query in seconds.
1. `make certora`: runs the Certora experiments; results are written in the README.
1. `make all`: runs experiments with all verification tools and generates the complete README.
1. `make clean`: removes build directories from verification tool directories.
1. `make clean-solcmc`: removes solcmc build directories.
1. `make clean-certora`: removes certora build directories.
1. `make cleanr`: removes the README.


### SolCMC directory structure

SolCMC directories contain:

- `Makefile`: to setup and run solcmc experiments.
- Property files.

#### SolCMC Instrumentation
Four types of instrumentation are available for SolCMC verification: ghost state, function
preghosts, function postghosts, and invariants. To apply these, use the
following tags within your property files:

- `/// @custom:ghost`: Defines ghost contract variables.
- `/// @custom:preghost function <function name>`: Defines ghost code to be executed before the body of a specific method.
- `/// @custom:postghost function <function name>`: Defines ghost code to be executed after the body of a specific method.
- `/// @custom:invariant`: Declares conditions that must remain valid throughout the entire contract execution, expressed through functions.

Example of a SolCMC property file:
```
/// @custom:ghost
uint _x = 0;
uint _y;

/// @custom:preghost constructor
require(_x > 0);

/// @custom:postghost constructor
assert(z < 10);

/// @custom:postghost function f1
assert(_y == 1);

/// @custom:invariant
function invariant(uint z) public {
    require(x != y);
    f1(x, y);
    f2();
    assert(x != y);
}
```

### Certora directory structure

Certora directories contain:
- `Makefile`: to setup and run certora experiments.
- `getters.sol`: a collection of getters for contract state variables, useful to write certora specifications.
- `methods.spec`: methods declaration to use in certora specifications.
- Specification files.

An example of a specification file:

```
rule P1 {
    env e;

    mathint y;
    x = getX();
    require x != y;

    f1(x,y);
    f2();

    assert x != y;
}
```

### Version-specific properties

Property files must follow the specified naming conventions:

- For general properties, the file should be named as `p<property_number>.sol`.
- If the property is associated with a specific contract version, use the
  format `p<property_number>_v<version_number>.sol`.

The tool manages the matching of properties and versions. It prioritizes
version-specific properties; if a version-specific definition of the property
exists, the tool will use it. Otherwise, it will default to the generic one.

### Property tags

Incorporate the following tags into your properties files to enable specific features of the benchmark:

- `/// @custom:nondef <note>`: Indicates the reason why a property is deemed
  nondefinable. When this tag is set, the associated experiment for this
  property will not be executed. Additionally, the specified note will appear
  to the automatically generated readme as a footnote.
- `/// @custom:negate`: Inverts the result provided by the tool.
