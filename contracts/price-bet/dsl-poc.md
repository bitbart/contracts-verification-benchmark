


#        "eventually-balance-zero": "eventually (i.e. at least once after the initial state) the contract balance goes to zero (assuming the fairness condition that `timeout()` is called at least once at a suitable time after the deadline).",
    NO (liveness)

#        "eventually-balance-zero-receive": "if the receive method of `owner` just accepts all ETH, eventually (i.e. at least once after the initial state) the contract balance goes to zero (assuming the fairness condition that `timeout()` is called at least once after the deadline).",

#        "eventually-withdraw": "if the player has joined, eventually (i.e. at least once after the initial state) a user can fire a transaction to withdraw at least twice the initial pot.",

#        "eventually-withdraw-receive-owner": "if the `receive` method of `owner` just accepts all ETH, and the player has joined, eventually (i.e. at least once after the initial state) a user can fire a transaction to withdraw at least twice the initial pot.",
#
#        "eventually-withdraw-receive-player": "if the `receive` method of `player` just accepts all ETH, and the player has joined, eventually (i.e. at least once after the initial state) a user can fire a transaction to withdraw at least twice the initial pot.",

#        "join-balance-eq": "after a non-reverting `join()`, the contract balance is equal to two times the `initial_pot`.",

#        "join-balance-geq": "after a non-reverting `join()`, the contract balance is greater than or equal to two times the `initial_pot`.",

#        "join-not-revert": "a transaction `join()` does not revert if the ETH amount sent along with the transaction is equal to `initial_pot`, no player has joined yet, and the deadline has not passed yet.",

#        "join-only-once": "a non-reverting `join()` transaction can only be fired once.",

#        "join-player": "after a non-reverting `join()`, `player` is not the zero address",

#        "join-revert": "a transaction `join()` reverts if the amount of ETH sent along with the transaction is different from `initial_pot`, or the `player` has already been set to a non-zero address, or the deadline has passed.",

#        "only-owner-or-player-receive":	"in any state where the player has been set, only the owner or the player can receive ETH from the contract.",

#        "owner-cannot-receive-before-deadline": "if the deadline has not passed yet, then the `owner` cannot receive ETH from the PriceBet contract.",

#        "owner-cannot-receive-before-deadline-not-player": "if the deadline has not passed yet and the `owner` is not the `player`, then the `owner` cannot receive ETH from the PriceBet contract.",

#        "owner-cannot-withdraw-before-deadline": "if the deadline has not passed yet, then the `owner` cannot fire a transaction (to the PriceBet contract) after which its ETH balance is increased.",

#        "owner-cannot-withdraw-before-deadline-not-player": "if the deadline has not passed yet and the `owner` is not the `player`, then the `owner` cannot fire a transaction (to the PriceBet contract) after which its ETH balance is increased.",

#        "player-cannot-withdraw-after-deadline": "if the deadline has passed, the `player` cannot withdraw any ETH.",

#        "player-cannot-withdraw-after-deadline-not-owner": "if the deadline has passed, and the `player` is not the `owner`, then the `player` cannot withdraw any ETH.",

#        "player-immutable": "if `player` is not the zero address, then its value does never change",

#        "price-above-player-win-frontrun": "if `player` is an EOA and it has not already fired a non-reverting `win`, and in some state before the deadline the value returned by a call `get_exchange_rate()` on the oracle goes above the target `exchange_rate`, then in any subsequent state before the deadline the `player` can fire a transaction after which its ETH balance is increased by the contract balance.",

#        "price-above-player-win": "if `player` is an EOA, and it has not already fired a non-reverting `win`, then in a state where the value returned by calling `get_exchange_rate()` on the oracle is above the target `exchange_rate` and the deadline has not passed, the `player` can fire a transaction after which its ETH balance is increased by the contract balance.",

#        "price-below-player-lose": "if the oracle exchange rate is always below the target `exchange_rate` before the deadline, then `player` cannot (neither before nor after the deadline) fire a transaction after which its ETH balance is increased.",

#        "price-below-player-lose-before-deadline-not-owner": "if the oracle exchange rate is below the target `exchange_rate` and the `player` is not the `owner`, then before the deadline the `player` cannot fire a transaction after which its ETH balance is increased.",

#        "price-below-player-lose-not-owner": "if the oracle exchange rate is always below the target `exchange_rate` before the deadline, and the `player` is not the `owner`, then `player` cannot (neither before nor after the deadline) fire a transaction after which its ETH balance is increased.",

#        "timeout-balance": "after a non-reverting `timeout()`, the ETH balance of `owner` is increased by the entire contract balance.",

#        "timeout-balance-receive": "if the `receive` method of `owner` just accepts all ETH, after a non-reverting `timeout()`, the ETH balance of `owner` is increased by the entire contract balance.",

#        "timeout-not-revert": "a transaction `timeout()` does not revert if the deadline has passed.",

#        "timeout-not-revert-receive": "if the `receive` method of `owner` just accepts all ETH, a transaction `timeout()` does not revert if the deadline has passed.",

#        "timeout-revert": "a transaction `timeout()` reverts if the deadline has not passed yet.",

#        "transfer-pot": "if some user manages to withdraw ETH from the contract, then the amount withdrawn by that user is at least twice the initial pot.",

#        "transfer-pot-join": "if some user has joined the bet (i.e. `player` is not the zero address) and some user manages to withdraw ETH from the contract, then the amount withdrawn by that user is at least twice the initial pot.",

#        "tx-assets-transfer-any": "eventually (i.e. at least once after the initial state), there exists some user who can perform some transaction after which the entire contract balance is trasferred to its own address.",

#        "tx-assets-transfer-owner": "eventually (i.e. at least once after the initial state), there exists some user who can perform some transaction after which the entire contract balance is trasferred to the `owner`.",

#        "win-balance": "after a non-reverting `win()`, the ETH balance of `player` is increased by the entire contract balance.",

#        "win-balance-receive": "if the `receive` method of `player` just accepts all ETH, then after a non-reverting `win()`, the ETH balance of `player` is increased by the entire contract balance.",

#        "win-frontrun": "if the `player` can win the bet, there exists an adversary that can frontrun the `player` to prevent him from actually winning.",

#        "win-frontrun-not-oracle": "if the `player` can win the bet, there exists an adversary different from the oracle owner who can frontrun the `player` to prevent him from actually winning.",

#        "win-not-revert": "a transaction `win()` does not revert if the deadline has not expired, the sender is the `player`, and the call to oracle returns an exchange rate that is greater than or equal to the target `exchange_rate`.",

#        "win-pot": "after a non-reverting `win()`, the ETH balance of `player` is increased by at least twice the initial pot.",

#        "win-pot-first-receive": "if the `receive` method of `player` just accepts all ETH, then after the first non-reverting `win()`, the ETH balance of `player` increases by at least twice the initial pot.",

#        "win-pot-receive": "if the `receive` method of `player` just accepts all ETH, then after a non-reverting `win()`, the ETH balance of `player` increases by at least twice the initial pot.",
#        

#        "win-revert": "a transaction `win()` reverts if the deadline has expired, or the sender is not the player, or the `exchange_rate` within the Oracle contract is less than the target `exchange_rate` within the PriceBet contract. Assume that the address `oracle` actually contains a deployment of contract Oracle."