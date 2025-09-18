# LendingProtocol

## Specification
The LendingProtocol contract implements a lending protocol that allows users to deposit tokens as collateral, earn interest on deposits, and borrow tokens.

The LendingProtocol contract handles ERC20-compatible tokens. No ETH is exchanged between the LendingProtocol and its users. 
Credits and debits are not represented as tokens, but as maps within the contract state:
- **debits** represent debt tokens that track how much users owe. These accrue interest over time.
- **credits** represent claim tokens that users receive when depositing. They appreciate in value over time as interests accrue on debits.

## Main functions

### Deposit

The action `deposit(amount,t)` allows 
the sender to deposit `amount` units of token `t`, receiving in exchange units of the associated credit token. 
The actual amount of received units is the product between `amount` and the exchange rate `XR(t)`, which is determined as follows:

```
XR(t) = (reserves[t] + total_debits[t]) * 1,000,000 / total_credits[t]
```

### Borrow

The action `borrow(amount, t)` allows 
the sender to borrow `amount` tokens of `t`, provided that they remains over-collateralized after the action.

### Repay

The action `repay(amount, t)` allows 
the sender to repay their debt of `amount` units of token `t`.

### Redeem

The action `redeem(amount, t)` allows 
the sender to withdraw `amount` units of token `t` that they deposited before. After the action, the user must remain over-collateralized.

### Liquidate

The action `liquidate(amount, t_debit, debtor, t_credit)` allows
the sender to repay a debt of `amount` units of token `t_debit` of `debtor`, receiving in exchange units of token `t_credit` seized from `debtor`. 


## Properties
- **bor-additivity**: if a sender A can perform two non-reverting `borrow()` without other transactions or interest accruals in between, of n1 and n2 token units (of the same token T, and in the same interest accrual period), then A can always obtain an equivalent effect (on the state of the contract and on its own token balance) through a single `borrow` of n1+n2 units of token T. Here equivalence neglects transaction fees. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **bor-reversibility**: if a sender A performs a non-reverting `borrow`, then A can fire a transaction that restores the amount of credits and debts of A to the state before the `borrow`. Here, assume that before performing the first transaction, the interests have already been accrued, for all token and users involved in the transaction. Assume that tokens are standard ERC20 tokens that do not charge fees on transfers.
- **bor-state**: if a user A performs a non-reverting `borrow(amount,T)`, then after the transaction: (1) the reserves of T in the `LendingProtocol` are decreased by `amt`; the debits of A in T are increased by `amt`; (3) the debits of A in all tokens different from T are preserved; (4) the credits of A in all tokens are preserved. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **bor-tokens**: if a user A performs a non-reverting `borrow(amount,T)`, then after the transaction: (1) the T balance of the `LendingProtocol` is decreased by `amt`; (2) the T balance of A is incremented by `amt`. Assume that `token` is a standard ERC20 token that do not charge fees on transfers.
- **bor-xr-eq**: the XR(T) of any token T handled by the `LendingProtocol` is preserved by any transaction `borrow(amount,token)`, if the interests on T have already been accrued. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **credits-zero**: if the summation over all users of the credits of a token T managed by the `LendingProtocol` are zero, then also the summations of the debits of T and of the reserves of T are zero.
- **credits-zero-notrunc**: if the summation over all users of the credits of a token T managed by the `LendingProtocol` are zero, then also the summations of the debits of T and of the reserves of T are zero. Assume that arithmetic is exact: integer operations do not overflow and do not lead to truncations.
- **dep-additivity**: if a sender A can perform two (non-reverting) `deposit` of n1 and n2 token units (of the same token T), then A can always obtain an equivalent effect (on the state of the contract and on its own token balance) through a single `deposit` of n1+n2 units of token T. Here equivalence neglects transaction fees. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **dep-gain-eq**: Define the net worth of A as the of the value of tokens in A's wallet (value of T = number of T units * price(T)), plus the value of A's credits (value of credit in T = number of A's credits in T * price(T) * XR(T) / 1e6) minut the value of A's debits (value of debit in T = number of A's debits in T * price(T). Then, a deposit transaction fired by A preserves A's net worth. Assume that all tokens are ERC20 tokens that do not charge fees on transfers.
- **dep-gain-eq-notrunc**: Define the net worth of A as the of the value of tokens in A's wallet (value of T = number of T units * price(T)), plus the value of A's credits (value of credit in T = number of A's credits in T * price(T) * XR(T) / 1e6) minut the value of A's debits (value of debit in T = number of A's debits in T * price(T). Then, a deposit transaction fired by A preserves A's net worth. Assume that all tokens are ERC20 tokens that do not charge fees on transfers. Assume that arithmetic is exact: integer operations do not overflow and do not lead to truncations.
- **dep-rdm-reverse**: if a sender A performs a (non-reverting) `deposit` of n1 token units and then a (non-reverting) `withdraw` of n1*1000000/XR(token_addr), then the amount of the credits and debts of A is restored to that in the state before the `deposit`. Assume that before performing the first transaction, the interests have already been accrued, for all token and users involved in the transaction.
- **dep-reversibility**: if a sender A performs a (non-reverting) `deposit`, then A can fire a transaction that restores the amount of credits and debts of A to the state before the `deposit`. Assume that before performing the first transaction, the interests have already been accrued, for all token and users involved in the transaction.
- **dep-reversibility-collateralized**: if a sender A performs a (non-reverting) `deposit`, and A is collateralized, then A can fire a transaction that restores the amount credits and debts of A to the state before the `deposit`. Here, assume that before performing the first transaction, the interests have already been accrued, for all token and users involved in the transaction.
- **dep-state**: if a user A performs a non-reverting `deposit(amount,T)`, then after the transaction: (1) the reserves of T in the `LendingProtocol` are increased by `amt`; the credits of A in T are increased by `amt` * 1e6 divided by the exchange rate of T the pre-state; (3) the credits of A in all tokens different from T are preserved; (4) the debits of A in all tokens are preserved. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **dep-tokens**: if a user A performs a non-reverting `deposit(amount,T)`, then after the transaction: (1) the T balance of the `LendingProtocol` is increased by `amt`; (2) the T balance of A is decreased by `amt`. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **dep-xr**: let XR(T) be the exchange rate of a token T handled by the `LendingProtocol` in a given state, and let XR'(T) be the exchange rate after a non-reverting transaction `deposit(amount,token)`. Then, XR(T) <= XR'(T) <= XR(T) + floor((amount * 1e6) / sum_credits[T]) + 1. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **dep-xr-eq**: the exchange rate XR(T) of any `token` handled by the `LendingProtocol` is preserved by any transaction `deposit(amount,T)`. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **dep-xr-eq-notrunc**: the exchange rate XR(T) of any `token` handled by the `LendingProtocol` is preserved by any transaction `deposit(amount,T)`. Assume that T is a standard ERC20 token that do not charge fees on transfers. Assume that arithmetic is exact: integer operations do not overflow and do not lead to truncations.
- **expected-interest**: the interest after one single accrual should not be doubled if two `borrow()` were executed before
- **int-xr-gneq**: after an interest accrual transaction, the exchange rate XR(T) of any token T for which there are are non-zero debits strictly increases.
- **rdm-additivity**: if a sender A can perform two consecutive (non-reverting) `redeem()`, without interest accruals in between, of n1 and n2 token units (of the same token T, and in the same interest accrual period), then A can always obtain an equivalent effect (on the state of the contract and on its own token balance) through a single `redeem` of n1+n2 units of token T. Here equivalence neglects transaction fees.
- **rdm-reversibility**: if a sender A performs a (non-reverting) `redeem`, then A can fire a transaction that restores the amount of credits and debts of A to the state before the `redeem`. Here, assume that before performing the first transaction, the interests have already been accrued, for all token and users involved in the transaction.
- **rdm-state**: if a user A performs a non-reverting `redeem(amount,T)`, then after the transaction, (1) the `LendingProtocol` reserves of T are decreased by `amt * XR(T) / 1e6` (where XR(T) is that in the pre-state); the credits of A in T are decreased by `amt`; (3) the credits of A in all tokens different from T are preserved. Assume that T is a standard ERC20 token.
- **rdm-tokens**: if a user A performs a non-reverting `redeem(amount,T)`, then after the transaction: (1) the T balance of the `LendingProtocol` is decreased by `amt * XR(T) / 1e6`; (2) the T balance of A is increased by `amt * XR(T) / 1e6`. Assume that XR(T) in is that in the pre-state, and that T is a standard ERC20 token that do not charge fees on transfers.
- **rdm-xr-eq**: the exchange rate XR(T) of any token T handled by the `LendingProtocol` is preserved by any transaction `redeem(amount,T)`. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **rpy-additivity**: if a sender A can perform two consecutive (non-reverting) `repay()`, without interest accruals in between, of n1 and n2 units of the same token T (and in the same interest accrual period), then A can always obtain an equivalent effect (on the state of the contract and on its own token balance) through a single `repay` of n1+n2 units of T. Here equivalence neglects transaction fees. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **rpy-reversibility**: if a user A performs a (non-reverting) `repay`, then after that transaction A can fire another transaction that restores the amount of credits and debts of A to the state before the `repay`. Here, assume that before performing the first transaction, the interests have already been accrued, for all token and users involved in the transaction.
- **rpy-state**: if a user A performs a non-reverting `repay(amount,T)`, then after the transaction: (1) the reserves of T in the `LendingProtocol` are increased by `amt`; the debits of A in T are decreased by `amt`; (3) the debits of A in all tokens different from T are preserved; (4) the credits of A in all tokens are preserved. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **rpy-tokens**: if a user A performs a non-reverting `repay(amount,T)`, then after the transaction: (1) the T balance in the `LendingProtocol` is increased by `amt`; the T balance of A is decreased by `amt`. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **rpy-xr-eq**: the exchange rate XR(T) of any token T handled by the `LendingProtocol` is preserved by any transaction `repay(amount,T)`. Assume that T is a standard ERC20 token that do not charge fees on transfers.
- **trace1**: From the initial state, consider the sequence of transactions: (1) A deposits 50 units of T0, (2) B deposits 50 units of T1, (3) B borrows 30 units of T0. Then, after that sequence: (1) the contract has reserves of 20 units of T0 and 50 units of T1, (2) A has 50 credits of T0, 0 debits of T1 and 0 debits, (3) B has 50 credits of T1 and 30 debits of T0
- **xr-geq-one**: for each token T handled by the lending protocol, the exchange rate XR(T) is always greater than or equal to 1000000
- **xr-increasing**: Let T be a token handled by the lending protocol, and assume that T is a standard ERC20 token. Then, `deposit`, `borrow`, `repay` and `redeem` transactions do not decrease XR(T). Assume that before performing the transaction, the interests on T have already been accrued for all users affected by the transaction.
- **xr-increasing-but-rdm**: Let T be a token handled by the lending protocol, and assume that T is a standard ERC20 token. Then, `deposit`, `borrow`, `repay` and `redeem` transactions do not decrease XR(T), except for a `redeem`  after which the total credits becomes zero. Assume that before performing the transaction, the interests on T have already been accrued for all users affected by the transaction.
- **xr-invariant**: for each token type T handled by the lending protocol, any transaction of type `deposit`, `borrow`, `repay` preserve the exchange rate XR(T). Assume that before performing the transaction, the interests have already been accrued, for all token and users involved in the transaction.

## Versions
- **v1**: minimal implementation without liquidation
- **v2**: compound interests inspired by Aave v1 
- **v3**: faulty version that could duplicate borrowers after a `borrow`, leading to incorrect interest accruals
- **v4**: `redeem` keeps 1 token for the contract (based on v1)
- **v5**: `repay` overwrites `token_addr` to `tok1` (based on v2)
- **v6**:  `redeem` keeps 1 token for the contract (based on v2)
- **v7**: `repay`  overwrites `token_addr` into `tok1` (based on v1)
- **v8**: fixed XR (based on v1)
- **v9**: fixed XR (based on v2)

## Verification data

- [Ground truth](ground-truth.csv)
- [Solcmc/z3](solcmc-z3.csv)
- [Solcmc/Eldarica](solcmc-eld.csv)
- [Certora](certora.csv)

