
#        "cancel-not-revert": "a `cancel()` transaction does not revert if the sender uses the recovery key, and the state is REQ.",
    similar

#        "cancel-revert": "a `cancel()` transaction reverts if the signer uses a key different from the recovery key, or the state is not REQ.",
    similar

#       "finalize-assets-transfer": "after a non-reverting `finalize()`, exactly `amount` wei are transferred from the contract balance to the receiver.",
    similar

#        "finalize-assets-transfer-receive": "after a non-reverting `finalize()`, if the `receive` method of `receiver` just accepts all ETH, then exactly `amount` wei are transferred from the contract to the receiver.",
    TODO check (how to encode "just accepts all ETH?")


#        "finalize-before-deadline-revert": "a `finalize()` transaction called immediately after a non-reverting `withdraw()` recerts if sent before `wait_time` blocks have elapsed since the call to `withdraw()`.",
    TODO (uses block number)


#        "finalize-not-revert": "a `finalize()` transaction does not revert if it is sent by the owner, in state REQ, and at least `wait_time` blocks have elapsed after `request_timestamp`.",
    similar

#        "finalize-not-revert-eoa": "a `finalize()` transaction does not revert if it is sent by the owner, in state REQ, at least `wait_time` blocks have elapsed after `request_timestamp`, and the `receiver` is an EOA.",
    TODO (similar to bank/withdraw-sender-rcv-EOA but here is the receiver being an EOA, not the sender)

#        "finalize-or-cancel-twice-revert": "a `finalize()` or `cancel()` transaction reverts if performed immediately after another `finalize()` or `cancel()`.",
    similar

#        "finalize-revert": "a `finalize()` transaction reverts if the sender is not the owner, or if the state is not REQ, or `wait_time` blocks have not passed since request_time.",
    similar

#        "finalize-sent-eq-amount": "after a non-reverting `finalize()`, the contract balance is decreased by exactly `amount` wei.",
    similar

#        "finalize-sent-leq-amount": "after a non-reverting `finalize()`, the contract balance is decreased by at most `amount` wei.",
    similar

#        "keys-distinct": "in any contract state, the owner key and the recovery key are distinct.",
    TODO check

#        "keys-invariant-inter": "after the contract is deployed, in any blockchain state the owner key and the recovery key cannot be changed.",
    TODO

#        "keys-invariant-intra": "after the contract is deployed, during the execution of a transaction, the owner key and the recovery key cannot be changed.",
    NO (cannot specify intra-function, TODO check)

#        "okey-rkey-private-withdraw": "if some user A knows both the owner and recovery key, and no one else knows the recovery key, then (in every fair trace) A is able to eventually transfer to any EOA of her choice any fraction of the contract balance, while no one else has the same ability. Assume `wait_time` is small enough to avoid overflows",
    NO (I think)

#        "receive-not-revert": "anyone can always send tokens to the contract",
    NO (liquidity)

#        "rkey-no-withdraw": "if some user knows the recovery key, they can always prevent other users from withdrawing funds from the contract.",
    TODO check

#        "state-idle-req-inter": "in any blockchain state, the Vault state is IDLE or REQ",
    TODO

#        "state-idle-req-intra": "during the execution of a transaction, the Vault state is always IDLE or REQ.",
    NO (intra-function)

#        "state-req-amount-consistent": "if the state is REQ, then `amount` is less than or equal to the contract balance.",
    similar

#        "state-update": "the contract implements a state machine with transitions: s -> s upon a `receive` (for any s), IDLE -> REQ upon a `withdraw`, REQ -> IDLE upon a `finalize` or a `cancel`.",
    TODO

#        "state-update-receive": "if the `receive` method of `receiver` just accepts all ETH, the contract implements a state machine with transitions: s -> s upon a receive (for any s), IDLE -> REQ upon a withdraw, REQ -> IDLE upon a finalize or a cancel.",
    TODO check condition on receive method?

#        "tx-idle-req": "if the state is IDLE, someone can fire a transaction that updates the state to REQ.",
    NO (liquidity)

#        "tx-idle-req-eoa": "if the state is IDLE and `owner` is an EOA, someone can fire a transaction that updates the state to REQ.",
    NO (liquidity)

#        "tx-owner-assets-transfer": "if the state is REQ and `wait_time` has passed since `request_time`, the `owner` can fire a transaction that transfers `amount` wei from the Vault to the `receiver`.",
    NO (liquidity)


#        "tx-owner-assets-transfer-eoa": "if the state is REQ, `wait_time` has passed since `request_time`, and both `owner` and `receiver` are EOAs, then the owner can fire a transaction that transfers `amount` wei from the Vault to the receiver.",
    NO (liquidity)

#        "tx-req-idle": "if the state is REQ, someone can fire a transaction that updates the state to IDLE.",
    NO (liquidity)

#        "tx-req-idle-eoa": "if the state is REQ and the recovery address passed to the constructor is a non-zero EOA, someone can fire a transaction that updates the state to IDLE.",
    NO (liquidity)

#        "tx-tx-amount-transfer-eoa-private": "if `owner` is an EOA and the adversary does not know the recovery key, then in state IDLE, the owner can fire a sequence of transactions that transfers any chosen fraction of the contract balance to any chosen EOA, regardless of possible transactions fired by the adversary before or in between.",
    NO (liquidity)

#        "tx-tx-assets-transfer": "in state IDLE, someone can fire a sequence of transactions that transfers the entire contract balance to a chosen EOA, regardless of possible transactions fired by the adversary before or in between.",
    NO (liquidity)

#       "tx-tx-assets-transfer-eoa": "if `owner` is an EOA, then in state IDLE, someone can fire a sequence of transactions that transfers the entire contract balance to a chosen EOA, regardless of possible transactions fired by the adversary before or in between.",
    NO (liquidity)

#        "tx-tx-assets-transfer-eoa-private": "if `owner` is an EOA and the adversary does not know the recovery key, then in state IDLE, the owner can fire a sequence of transactions that transfers the contract balance to a chosen EOA, regardless of possible transactions fired by the adversary before or in between.",
    NO (liquidity)

#        "withdraw-finalize-not-revert": "a `finalize()` transaction called by the `owner` after a non-reverting `withdraw()` (with no other transactions executed in between) does not revert if sent after `wait_time` blocks have elapsed.",
    similar

#        "withdraw-finalize-not-revert-eoa": "if the `receiver` is an EOA, a `finalize()` transaction called by the `owner` after a non-reverting `withdraw()` (with no other transactions executed in between) does not revert if sent after `wait_time` blocks have elapsed.",
    similar

#        "withdraw-finalize-revert-inter": "a `finalize` transaction called before `wait_time` since a non-reverting `withdraw`, possibly with in-between transactions, reverts.",
    TODO

#        "withdraw-not-revert": "a `withdraw(amount)` transaction does not revert if `amount` is less than or equal to the contract balance, the sender is the owner, and the state is IDLE.",
    similar

#       "withdraw-revert": "a `withdraw(amount)` transaction reverts if `amount` is more than the contract balance, or if the sender is not the owner, or if the state is not IDLE.",
    similar

#        "withdraw-withdraw-revert": "a `withdraw()` transaction reverts if fired immediately after another non-reverting `withdraw()`."
    similar