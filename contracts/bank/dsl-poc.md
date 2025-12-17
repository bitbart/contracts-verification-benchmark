

# "assets-dec-onlyif-deposit": "if the ETH balance of a user A is decreased after a transaction (of the Bank contract), then that transaction must be a `deposit` where A is the sender.",
    OK

# "assets-inc-onlyif-withdraw": "if the ETH balance of a user A is increased after a transaction (of the Bank contract), then that transaction must be a `withdraw` where A is the sender.",
    similar to "assets-dec-onlyif-deposit"

# "credit-dec-onlyif-withdraw": "if the credit of a user A is decreased after a transaction (of the Bank contract), then that transaction must be a `withdraw` where A is the sender.",
    similar to "assets-dec-onlyif-deposit"

# "credit-inc-onlyif-deposit": "if the credit of a user A is increased after a transaction (of the Bank contract), then that transaction must be a `deposit` where A is the sender.",
    similar to "assets-dec-onlyif-deposit"

# "credits-leq-balance": "the wei balance stored in the contract is greater than or equal to the sum of all the users' credits", 
    NO: not clear how to loop over maps

# "deposit-additivity": "two non-reverting consecutive (i.e., not interleaved with other transactions) `deposit` of n1 and n2 wei performed by the same sender are equivalent to a single `deposit` of n1+n2 wei of T.",
    OK

# "deposit-assets-credit": "after a non-reverting `deposit()`, the credits of `msg.sender` are increased by `msg.value`.",
    TODO (check how to assert "non-reverting")

# "deposit-assets-credit-others": "after a non-reverting `deposit()`, the credit of any user but the sender is preserved.",
    TODO

# "deposit-assets-transfer-others": "after a non-reverting `deposit()`, the ETH balance of any user but the sender are preserved.",
    similar to "deposit-assets-credit-others"

# "deposit-contract-balance": "after a non-reverting `deposit()`, the ETH balance of the contract is increased by `msg.value`.",
    similar to "deposit-assets-credit"

# "deposit-not-revert-external": "an external `deposit` transaction never reverts",
    TODO check

# "deposit-not-revert": "a `deposit` transaction never reverts",
    TODO check if interesting

# "deposit-revert": "a `deposit` transaction reverts if `msg.value` plus the current credits of `msg.sender` overflows.",
    OK

# "exists-at-least-one-credit-change": "after a non-reverting `deposit` or `withdraw` transaction to the Bank contract, the credits of at least one user have changed",
    NO (forall on addresses)

# "exists-unique-asset-change": "after a non-reverting `deposit` or `withdraw` transaction to the Bank contract, the ETH balance of exactly one account (except the contract's) have changed",
    TODO

# "exists-unique-credit-change": "after a non-reverting `deposit` or `withdraw` transaction to the Bank contract, the credit of exactly one user have changed",
    similar to "exists-unique-asset-change"

# "no-frozen-assets": "if the contract has a strictly positive ETH balance, then someone can transfer them from the contract to some user",
    NO: liquidity (TODO: use LLM to synthesize strategy, and then prove it always work with e.g. Kontrol?)

# "no-frozen-credits": "if the sum of all the credits is strictly positive, it is possible to reduce them",
    NO: not clear how to loop over maps

# "withdraw-additivity": "if the same sender can perform two non-reverting consecutive (i.e., not interleaved with other transactions) `withdraw` of n1 and n2 wei, respectively, then the same sender can always obtain an equivalent effect (on the state of the Bank contract and on its own account) through a single `withdraw` of n1+n2 wei. Here equivalence neglects transaction fees.",
    similar to "deposit-additivity"

# "withdraw-assets-credit-others": "after a non-reverting `withdraw(amount)`, the credit of any user (except, possibly, the sender) is preserved.",
    similar to "deposit-assets-credit-others"

# "withdraw-assets-transfer-others": "after a non-reverting `withdraw(amount)`, the ETH balance of any user (except, possibly, the sender) are preserved.",
    similar to "deposit-assets-transfer-others"

# "withdraw-contract-balance": "after a non-reverting `withdraw(amount)`, the contract balance is decreased by `amount` wei.",
    similar to "deposit-contract-balance"

# "withdraw-not-revert": "a `withdraw(amount)` call does not revert if `amount` is bigger than zero and less or equal to the credit of `msg.sender`.",
    similar to "deposit-not-revert"

# "withdraw-revert": "a `withdraw(amount)` call reverts if `amount` is zero or greater than the credit of `msg.sender`.",
    similar to "deposit-revert"

# "withdraw-sender-credit": "after a non-reverting `withdraw(amount)`, the credit of `msg.sender` is decreased by `amount`.",
    similar to "deposit-assets-credit":

# "withdraw-sender-rcv": "after a non-reverting `withdraw(amount)`, the ETH balance of `msg.sender` is increased by `amount` wei.",
    TODO

# "withdraw-sender-rcv-EOA": "after a non-reverting `withdraw(amount)` originated by an EOA, the ETH balance of the `msg.sender` is increased by `amount` wei."
    TODO





