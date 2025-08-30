# Payment Splitter

## Specification
This contract allows to split ETH payments among a group of users. The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each account to a number of shares.

At deployment, the contract creator specifies the set of users who will receive the payments and the corresponding number of shares. The set of shareholders and their shares cannot be updated thereafter.

After creation, the contract supports the following actions:
- `receive`, which allows anyone to deposit ETH in the contract;
- `release`, which allows anyone to distribute the contract balance to the shareholders. Each shareholder will receive an amount proportional to the percentage of total shares they were assigned. 

The contract follows a pull payment model. This means that payments are not automatically forwarded to the accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the `release()` function.

## Properties
- **fair-split-eq**: for every address `a` in `payees`, `released[a] + releasable(a) == (totalReceived * shares[a]) / totalShares`.
- **fair-split-geq**: for every address `a` in `payees`, `(totalReceived * shares[a]) / totalShares >= released[a]`.
- **non-zero-payees**: for all addresses `a` in `payees`, `a != address(0)`.
- **positive-shares**: for all addresses `addr` in `payees`, `shares[addr] > 0`.
- **releasable-balance-check**: for all addresses `addr` in `payees`, `releasable(addr)` is less than or equal to the balance of the contract.
- **releasable-sum-balance**: the sum of the releasable funds for every addresses is equal to the balance of the contract.
- **release-not-revert**: for all addresses `a` in `payees`, if `releasable(a) > 0`, then `release(a)` does not revert.
- **release-release-revert**: two consecutive calls to `release` for the same address `a`, without there being any transfer to the contract in between calls, revert on the second call.
- **swappable-call-order**: given two `payees` `a` and `b`, with `a != b`, calling `release(a)` and `release(b)`, independently of the order of the calls, yields the same contract state.

## Versions
- **v1**: minimal implementation conformant to specification
- **v2**: loop-free version with a fixed number of payees (set to 3)
- **v3**: loop-free version with a fixed number of payees (set to 3) and equal shares
- **v4**: variant with unchecked release
- **v5**: faulty implementation with a parenthesis error in `pendingPayment`

## Verification data

- [Ground truth](ground-truth.csv)
- [Solcmc/z3](solcmc-z3.csv)
- [Solcmc/Eldarica](solcmc-eld.csv)
- [Certora](certora.csv)

