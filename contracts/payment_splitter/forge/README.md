## Forge PoCs 

The [test](test) directory contains Forge implementations of the PoCs produced by GPT-5.

## Setup

Install [Foundry](https://getfoundry.sh/introduction/installation/#installation):
```bash
curl -L https://foundry.paradigm.xyz | bash

foundryup
```

From the `payment_splitter` folder, initialize a forge project:
```bash
forge init forge --force --empty
```

Copy the contract sources in the `src` folder: 
```bash
cp -r ../versions/* src/
```

## Usage

To run the PoCs:
```bash
forge test
```

Incorrect PoCs (not showing a property violation) will result in assertion violations, and displayed in red.  