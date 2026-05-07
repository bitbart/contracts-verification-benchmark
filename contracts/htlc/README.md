# HTLC

## Specification
The Hash Timed Locked Contract (HTLC) involves two users, the *owner* and the *verifier*, and it allows the owner to commit to a secret and reveal it afterwards, within a given deadline. 

The commitment is the SHA256 digest of the secret (a bitstring). At contract creation, the owner specifies the verifier, who will receive the collateral in case the deposit is not revealed within the deadline. 

The deadline expires 1000 blocks after the block where the contract has been deployed: if deployment is at block N, `timeout` can be called in a block with height strictly greater than N+1000.

After contract creation, the HTLC allows the following actions:
- `commit` requires the owner to deposits a collateral (at least 1 ETH) in the contract, and records the commitment;
- `reveal` allows the owner to withdraw the whole contract balance, by revealing a preimage of the committed secret;
- `timeout` can be called by anyone only after the deadline, and tranfers the whole contract balance to the verifier.

## Properties
- **commit-auth-owner**: If `commit` is successfully called, then the sender must be the owner.
- **reveal-auth-owner**: If `reveal` is successfully called, then the sender must be the owner.
- **reveal-timeout-after-commit**: `reveal` and `timeout` can only be called after `commit`.
- **sent-le-init-bal**: The overall sent amount does not exceed the initial deposit.
- **timeout-deadline**: If `timeout` is called, then at least 1000 blocks have passed since the contract was deployed.

## Versions
- **v1**: conformant to specification.
- **v2**: removed check that `commit` can only be called before `reveal` and `timeout`.
- **v3**: `timeout` can be called since block N+999 (included).
- **v4**: `timeout` transfers balance to `msg.sender` instead of verifier.
- **v5**: removed check that `commit` can only be called by `owner`.
- **v6**: removed check that `reveal` can only be called by `owner`.
- **v7**: `reveal` and `timeout` reset `isCommitted` to `false`. 
- **v8**: removed check that hash of string argument of `reveal` equals saved hash
- **v9**: removed check that `commit`should be called with a `msg.value` of at least 1 ETH.

## Verification data

- [Ground truth](ground-truth.csv)
- [Solcmc/z3](solcmc-z3.csv)
- [Solcmc/Eldarica](solcmc-eld.csv)
- [Certora](certora.csv)