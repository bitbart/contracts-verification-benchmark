# Bank

## Specification
The Bank contract stores assets deposited by users, and and pays them out when required. 
- the `deposit` method allows anyone to deposit ETH. When a deposit is made, the corresponding amount is added to the account balance of the sender. 
- the `withdraw` method allows the sender to receive any desired amount of ETH deposited in their account.

## Properties
- **assets-dec-onlyif-deposit**: if the ETH balance of a user A is decreased after a transaction (of the Bank contract), then that transaction must be a `deposit` where A is the sender.
- **assets-inc-onlyif-withdraw**: if the ETH balance of a user A is increased after a transaction (of the Bank contract), then that transaction must be a `withdraw` where A is the sender.
- **credit-dec-onlyif-withdraw**: if the credit of a user A is decreased after a transaction (of the Bank contract), then that transaction must be a `withdraw` where A is the sender.
- **credit-inc-onlyif-deposit**: if the credit of a user A is increased after a transaction (of the Bank contract), then that transaction must be a `deposit` where A is the sender.
- **credits-leq-balance**: the wei balance stored in the contract is greater than or equal to the sum of all the users' credits
- **deposit-additivity**: two non-reverting consecutive (i.e., not interleaved with other transactions) `deposit` of n1 and n2 wei performed by the same sender are equivalent to a single `deposit` of n1+n2 wei of T.
- **deposit-assets-credit**: after a non-reverting `deposit()`, the credits of `msg.sender` are increased by `msg.value`.
- **deposit-assets-credit-others**: after a non-reverting `deposit()`, the credit of any user but the sender is preserved.
- **deposit-assets-transfer-others**: after a non-reverting `deposit()`, the ETH balance of any user but the sender are preserved.
- **deposit-contract-balance**: after a non-reverting `deposit()`, the ETH balance of the contract is increased by `msg.value`.
- **deposit-not-revert**: a `deposit` transaction never reverts
- **deposit-not-revert-external**: an external `deposit` transaction never reverts
- **deposit-revert**: a `deposit` transaction reverts if `msg.value` plus the current credits of `msg.sender` overflows.
- **exists-at-least-one-credit-change**: after a non-reverting `deposit` or `withdraw` transaction to the Bank contract, the credits of at least one user have changed
- **exists-unique-asset-change**: after a non-reverting `deposit` or `withdraw` transaction to the Bank contract, the ETH balance of exactly one account (except the contract's) have changed
- **exists-unique-credit-change**: after a non-reverting `deposit` or `withdraw` transaction to the Bank contract, the credit of exactly one user have changed
- **no-frozen-assets**: if the contract has a strictly positive ETH balance, then someone can transfer them from the contract to some user
- **no-frozen-credits**: if the sum of all the credits is strictly positive, it is possible to reduce them
- **withdraw-additivity**: if the same sender can perform two non-reverting consecutive (i.e., not interleaved with other transactions) `withdraw` of n1 and n2 wei, respectively, then the same sender can always obtain an equivalent effect (on the state of the Bank contract and on its own account) through a single `withdraw` of n1+n2 wei. Here equivalence neglects transaction fees.
- **withdraw-assets-credit-others**: after a non-reverting `withdraw(amount)`, the credit of any user (except, possibly, the sender) is preserved.
- **withdraw-assets-transfer-others**: after a non-reverting `withdraw(amount)`, the ETH balance of any user (except, possibly, the sender) are preserved.
- **withdraw-contract-balance**: after a non-reverting `withdraw(amount)`, the contract balance is decreased by `amount` wei.
- **withdraw-not-revert**: a `withdraw(amount)` call does not revert if `amount` is bigger than zero and less or equal to the credit of `msg.sender`.
- **withdraw-revert**: a `withdraw(amount)` call reverts if `amount` is zero or greater than the credit of `msg.sender`.
- **withdraw-sender-credit**: after a non-reverting `withdraw(amount)`, the credit of `msg.sender` is decreased by `amount`.
- **withdraw-sender-rcv**: after a non-reverting `withdraw(amount)`, the ETH balance of `msg.sender` is increased by `amount` wei.
- **withdraw-sender-rcv-EOA**: after a non-reverting `withdraw(amount)` originated by an EOA, the ETH balance of the `msg.sender` is increased by `amount` wei.

## Versions
- **v1**: minimal implementation according to informal specification
- **v2**: no `amount <= credits[msg.sender]` check and `credits[msg.sender]` is decremented by `amount - 1` in `withdraw()`
- **v3**: `deposit` and `withdraw` limits for non-owner users, with owner exempt from limits; `withdraw` uses `transfer` instead of low-level call 
- **v4**: no `amount <= credits[msg.sender]` check and `credits[msg.sender]` is incremented by `amount - 1` in `deposit`
- **v5**: no `amount <= credits[msg.sender]` check and `credits[msg.sender]` is incremented by `amount + 1` in `deposit`
- **v6**: no `amount <= credits[msg.sender]` check and `amount + 1` is transferred to `msg.sender` in `withdraw`
- **v7**: `deposit` pays a unit fee to the owner
- **v8**: `withdraw` is non-reentrant
- **v9**: `deposit` and `withdraw` are non-reentrant
- **v10**: owner can pause `withdraw`
- **v11**: owner can pause `deposit`
- **v12**: missing `require(success)` after low-level call in `withdraw`
- **v13**: `deposit` transfers part of `msg.value` to the owner
- **v14**: owner can blacklist addresses from `deposit` and `withdraw`
- **v15**: maximum number of operations per block, and uses `transfer` instead of low-level call in `withdraw`.
- **v16**: in `withdraw`, no `amount <= credits[msg.sender]` check, unchecked decrement, and no `require(success)` check
- **v17**: `withdraw` subtracts credits from `tx.origin`, but sends ETH to `msg.sender`

## Verification data

- [Ground truth](ground-truth.csv)
- [Solcmc/z3](solcmc-z3.csv)
- [Solcmc/Eldarica](solcmc-eld.csv)
- [Certora](certora.csv)

