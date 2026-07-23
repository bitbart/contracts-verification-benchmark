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
- **balance-only-increases-on-commit**: The contract's balance should increase only if the `commit()` function is called
- **cant-uncommit**: If contract is in a committed state, no function should be able to reverse it back to an uncommited state
- **commit-auth-owner**: If `commit()` is successful, then `msg.sender` must be the contract's owner
- **commit-minimum**: If `commit()` is successful, then `msg.value` is greater than or equal to `fee`
- **commit-not-revert-isCommitted-was-false**: If `commit()` is successful, then isCommitted was false before the call
- **commit-reverts-if-isCommitted**: If contract is already in a committed state, then any following `commit()` calls must revert
- **commit-twice-reverts**: After a succesful `commit()` call, any immediate following calls to `commit()` must revert
- **contract-balance-is-commit-value**: After a successful call to `commit()`, the contract's balance must be equal to `msg.value`
- **owner-immutable**: No succesful function call should change contract's owner
- **reveal-auth-owner**: If `reveal()` is successful, then `msg.sender` must be the contract's owner
- **reveal-preimage**: If `reveal(s)` does not revert, then `s` is a preimage of the committed hash
- **reveal-timeout-after-isCommitted**: `reveal()` and `timeout()` can only be successfully called if contract is in a committed state
- **reveal-transfer**: If `reveal()` is successful, `owner`'s balance must increase by at least the balance of the contract
- **reveal-zeroes-balance**: If `reveal()` is successful, it must completely drain the contract's balance
- **sent-le-init-bal**: The overall sent amount does not exceed the initial deposit.
- **timeout-deadline**: If `timeout()` is successful, the transaction must have occurred at a block number greater than or equal to the contract's initial block plus `waitTime`
- **timeout-transfer**: If `timeout()` is successful, `verifier`'s balance must increase by at least the balance of the contract
- **timeout-zeroes-balance**: If `timeout()` is successful, it must completely drain the contract's balance
- **verifier-immutable**: No function call should change the address of the verifier
- **wrong-preimage-reverts**: Attemps to call `reveal()` with wrong preimage of committed hash should revert

## Versions
- **v1**: conformant to specification.
- **v2**: removed check that `commit` can only be called before `reveal` and `timeout`.
- **v3**: `timeout` can be called since block N+999 (included).
- **v4**: `timeout` transfers balance to `msg.sender` instead of verifier.
- **v5**: removed check that `commit` can only be called by `owner`.
- **v6**: removed check that `reveal` can only be called by `owner`.
- **v7**: `reveal` and `timeout` reset `isCommitted` to `false`
- **v8**: removed check that revealed string is a pre image of committed hash
- **v9**: removed check that `commit` should be called with a `msg.value` of at least 1 ETH.
- **v10**: call to `reveal` transfers balance to `verifier` instead of `owner`
- **v11**: wrong timeout eth receiver.
- **v12**: `reveal` function may be bribed to change committed `hash`
- **v13**: `timeout` function may be bribed to change `verifier` address
- **v14**: `reveal` function may be bribed to change `owner` address

## Verification data

- [Ground truth](ground-truth.csv)
- [Solcmc/z3](solcmc-z3.csv)
- [Solcmc/Eldarica](solcmc-eld.csv)
- [Certora](certora.csv)

## Experiments
