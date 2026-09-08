# AMM

## Specification
# AMM Specification

The Automated Market Maker (AMM) contract allows users to provide liquidity and swap tokens using a constant product formula ($x \times y = k$).

## Core Features
- **Deposit**: Users can add liquidity to the pool in exchange for LP (Liquidity Provider) tokens.
- **Redeem**: Users can burn their LP tokens to withdraw their proportional share of the underlying reserves.
- **Swap**: Users can trade one token for another.

## Requirements
- The contract maintains internal reserves (`r0` and `r1`).
- The AMM must not lock user funds without a valid economic reason.
- Operations should follow standard ERC20 token interactions.


## Properties
- **constant-product**: After a non-reverting `swap` transaction, the product of the contract's token balances is greater than or equal to the product before the transaction.
- **deposit-precision**: After a non-reverting `deposit` transaction where the deposited amounts are proportional to the reserves and are at least one-thousandth of the current reserves, the minted liquidity tokens are strictly positive and do not exceed the proportion between the deposited amounts and the contract's existing reserves.
- **deposit-precision-strict**: After a non-reverting `deposit` transaction where the deposited amounts are proportional to the reserves and are at least one-thousandth of the current reserves, the minted liquidity tokens are strictly positive and equal to the proportion between the deposited amounts and the contract's existing reserves.
- **donation-dos**: If the token balances of the contract exceed its reserves, a `redeem` transaction by a sender possessing a positive amount of liquidity tokens never reverts.
- **minimum-liquidity**: If the total supply of liquidity tokens is strictly positive, the amount of liquidity tokens minted to the zero address is always greater than or equal to 1000.
- **minimum-liquidity-strict**: If the total supply of liquidity tokens is strictly positive, the amount of liquidity tokens minted to the zero address is always equal to 1000.
- **price-bounds**: If the reserve of token0 is greater than the reserve of token1, the `price` function returns a value for token1 that is greater than the value for token0.
- **price-equality**: If the tracked reserves of the contract are equal and positive, the `price` function returns identical values for both token0 and token1.
- **price-symmetry**: The product of the prices of token0 and token1, as calculated by the `price` function, never exceeds 1e36.
- **price-symmetry-strict**: The product of the prices of token0 and token1, as calculated by the `price` function, is always equal to 1e36.
- **redeem-fairness**: After a non-reverting `redeem` transaction, the token balances of the sender must increase by an amount proportional to their fraction of the total supply, calculated against the contract's actual token balances.
- **redeem-liveness**: If the contract's tracked reserves are equal to its actual balances, a `redeem` transaction by a valid sender possessing a positive amount of liquidity tokens never reverts.
- **redeem-precision**: After a non-reverting `redeem` transaction of a strictly positive amount of liquidity tokens, the real token balances of the sender strictly increase.
- **reserves-not-drained**: If the tracked reserves of the contract are both strictly positive, then after any non-reverting transaction to the contract, the tracked reserves remain strictly positive.
- **swap-fee**: After a non-reverting `swap` transaction, the product of the contract's tracked reserves strictly increases.
- **swap-precision**: After a non-reverting `swap` transaction where `amountIn` is strictly positive and the minimum return is set to zero, the contract's balance of the output token is decreased.

## Versions
- **v1**: Bug 1 (Safe Baseline): Fixed Reentrancy & Unsafe transfers
- **v2**: Bug 2: Fixed Inflation Attack (added MINIMUM_LIQUIDITY)
- **v3**: Bug 3: Fixed Liveness and DoS
- **v4**: compliant with the specification.
- **v5**: Bug 5: Added Buggy Deposit (removes proportion check)
- **v6**: Bug 6: Added Broken Swap Math (drains pool)

## Verification data

- [Ground truth](ground-truth.csv)
- [Solcmc/z3](solcmc-z3.csv)
- [Solcmc/Eldarica](solcmc-eld.csv)
- [Certora](certora.csv)

## Experiments
### SolCMC
#### Z3
|        | constant-product         | deposit-precision        | deposit-precision-strict | donation-dos             | minimum-liquidity        | minimum-liquidity-strict | price-bounds             | price-equality           | price-symmetry           | price-symmetry-strict    | redeem-fairness          | redeem-liveness          | redeem-precision         | reserves-not-drained     | swap-fee                 | swap-precision           |
|--------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|
| **v1** | FN!                      | FN!                      | TN!                      | FN!                      | FN!                      | FN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | FN!                      | FN!                      | FN!                      | FN!                      | TN!                      |
| **v2** | FN!                      | FN!                      | TN!                      | TN!                      | FN!                      | FN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | FN!                      | FN!                      | FN!                      | FN!                      | TN!                      |
| **v3** | FN!                      | FN!                      | TN!                      | TN!                      | FN!                      | FN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | FN!                      | FN!                      | FN!                      | FN!                      | TN!                      |
| **v4** | FN!                      | FN!                      | TN!                      | TN!                      | FN!                      | FN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | FN!                      | FN!                      | FN!                      | FN!                      | TN!                      |
| **v5** | FN!                      | FN!                      | TN!                      | TN!                      | FN!                      | FN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | FN!                      | FN!                      | FN!                      | FN!                      | TN!                      |
| **v6** | FN!                      | TN!                      | TN!                      | TN!                      | TN!                      | TN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | TN!                      | TN!                      | FN!                      | FN!                      | TN!                      |
 


### Certora
|        | constant-product         | deposit-precision        | deposit-precision-strict | donation-dos             | minimum-liquidity        | minimum-liquidity-strict | price-bounds             | price-equality           | price-symmetry           | price-symmetry-strict    | redeem-fairness          | redeem-liveness          | redeem-precision         | reserves-not-drained     | swap-fee                 | swap-precision           |
|--------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|--------------------------|
| **v1** | FN!                      | TP!                      | TN!                      | FN!                      | FN!                      | FN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | FN!                      | FN!                      | TP!                      | FN!                      | TN!                      |
| **v2** | FN!                      | TP!                      | TN!                      | TN!                      | FN!                      | FN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | FN!                      | FN!                      | TP!                      | FN!                      | TN!                      |
| **v3** | FN!                      | FN!                      | TN!                      | TN!                      | FN!                      | FN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | FN!                      | FN!                      | TP!                      | FN!                      | TN!                      |
| **v4** | FN!                      | FN!                      | TN!                      | TN!                      | FN!                      | FN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | FN!                      | FN!                      | TP!                      | FN!                      | TN!                      |
| **v5** | FN!                      | FN!                      | TN!                      | TN!                      | FN!                      | FN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | FN!                      | FN!                      | TP!                      | FN!                      | TN!                      |
| **v6** | FN!                      | TN!                      | TN!                      | TN!                      | TN!                      | TN!                      | TP!                      | TP!                      | TP!                      | TN!                      | FN!                      | TN!                      | TN!                      | FN!                      | FN!                      | TN!                      |
 

