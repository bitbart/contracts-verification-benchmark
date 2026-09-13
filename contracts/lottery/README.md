# Lottery

## Specification
Consider a lottery where two players bet an equal amount of crypto-currency, and the winner - who is chosen fairly between the two players - redeems the whole pot.

Since smart contract are deterministic and external sources of randomness (e.g., random number oracles) might be biased, to achieve fairness we follow a *commit-reveal-punish* protocol, where both players first commit to the hash of the secret, then reveal their secret (which must be a preimage of the committed hash), and finally the winner is computed as a fair function of the secrets.

Implementing this protocol properly is quite error-prone, since the protocol must punish players who behave dishonestly, e.g. by refusing to perform some required action.
In this case, the protocol must still ensure that, on average, an honest player has at least the same payoff that they would have by interacting with another honest player. 

The protocol followed by (honest) players is the following:
1. `player0` joins the lottery by paying the bet and committing to a secret;
2. `player1` joins the lottery by paying the bet and committing to another secret (the bet is the same for each player)
3. if `player1` has not joined, `player0` can redeem their bet after a given deadline (`end_join`).
4. `player0` reveals the first secret;
5. if `player0` has not revealed, `player1` can redeem both players' bets after a given deadline (`end_reveal0`); 
6. once `player0` has revealed, `player1` reveals the secret;
7. if `player1` has not revealed, `player0` can redeem both players' bets after a given deadline (`end_reveal1`);
8. once both secrets have been revealed, the winner, who is fairly determined as a function of the two revealed secrets, can redeem the whole pot.

## Properties
- **deadlock-freedom-join1**: In status `Join1` if contract balance is positive, some user can perform a non-reverting transaction that empties the contract balance
- **deadlock-freedom-reveal0**: In status `Reveal0` if contract balance is positive, some user can perform a non-reverting transaction that empties the contract balance
- **deadlock-freedom-reveal1**: In status `Reveal1` if contract balance is positive, some user can perform a non-reverting transaction that empties the contract balance
- **deadlock-freedom-win**: In status `Win` if contract balance is positive, some user can perform a non-reverting transaction that empties the contract balance
- **honest-player-profitability-eoa-redeem0-nojoin1**: Assuming `player0` and `player1` behave as EOAs: in status `Join1`, a user can perform a non-reverting transaction, made after the status's respective deadline, that strictly increases `player0`'s ETH balance by exactly their bet, leaves the contract's ETH balance at zero, and advances status to `End`
- **honest-player-profitability-eoa-redeem0-noreveal1**: Assuming `player0` and `player1` behave as EOAs: in status `Reveal1`, a user can perform a non-reverting transaction, made after the status's respective deadline, that strictly increases `player0`'s ETH balance by exactly the pot, leaves the contract's ETH balance at zero, and advances status to `End`
- **honest-player-profitability-eoa-redeem1-noreveal0**: Assuming `player0` and `player1` behave as EOAs: in status `Reveal0`, a user can perform a non-reverting transaction, made after the status's respective deadline, that strictly increases `player1`'s ETH balance by exactly the pot, leaves the contract's ETH balance at zero, and advances status to `End`
- **no-incentives-to-abort-eoa**: After a non-reverting `reveal0` transaction, assuming `player0` is an EOA, if no `reveal1` is performed before the deadline, then `player0` can redeem the pot
- **owner-impartiality-eoa**: Assuming `player0` and `player1` are EOAs: in any status where the winner is not yet determined, for every transaction whose sender is neither `player0` nor `player1`; if such transaction changes the contract storage, then the same transaction (except for `msg.sender`), made by any EOA, in the same status, must produce the same state modifications
- **player1-should-match-bet**: If a `join1` transaction doesn't revert then `msg.value` matched the bet from `player0`
- **redeem-before-deadline-reverts-nojoin1**: A `redeem0_nojoin1` transaction reverts if it is performed before or at the `end_join` deadline
- **redeem-before-deadline-reverts-noreveal0**: A `redeem1_noreveal0` transaction reverts if it is performed before or at the `end_reveal0` deadline
- **redeem-before-deadline-reverts-noreveal1**: A `redeem0_noreveal1` transaction reverts if it is performed before or at the `end_reveal1` deadline
- **redeem0-noreveal1-fairness-eoa**: Assuming `player0` and `player1` behave as EOAs: if the contract is in `Reveal1` status and evaluating the fair function would result in `player0` being the winner; then a `redeem0_noreveal1` non-reverting transaction strictly increases `player0`'s ETH balance, leaves `player1`'s ETH balance unchanged, and strictly decreases the contract's ETH balance.
- **reveal0-reverts-after-deadline**: A `reveal0` transaction reverts if it is performed after the `end_reveal0` deadline
- **reveal1-reverts-after-deadline**: A `reveal1` transaction reverts if it is performed after the `end_reveal1` deadline
- **status-irreversible**: If a user performs a non-reverting transaction then the contract's status after the transaction is strictly greater than it was before
- **win-pays-fair-winner-eoa**: Assuming `player0` and `player1` are EOAs: if the honest protocol would result in `expected_winner` to be the winner of the lottery, a non-reverting `win` transaction must increase `expected_winner` ETH balance by the pot
- **win-transaction-env-independent**: Two non-reverting `win` transactions performed from equal contract state yield the same result
- **winner-computation-env-independent**: Given the same inputs, the fair win function yields the same output regardless of the environment
- **wrong-preimage-reverts-p0**: If a `reveal0(s)` transaction does not revert, then `s` is a preimage of the committed hash
- **wrong-preimage-reverts-p1**: If a `reveal1(s)` transaction does not revert, then `s` is a preimage of the committed hash

## Versions
- **v1**: conformant to specification
- **v2**: redeem0_nojoin1 transfers only half the balance
- **v3**: redeem1_noreveal0 transfers only half the balance
- **v4**: redeem0_noreveal1 transfers only half the balance
- **v5**: win transfers only half the balance
- **v6**: redeem0_noreveal1 sends to player1 instead of player0
- **v7**: missing status check in join1
- **v8**: missing status check in reveal0
- **v9**: missing status check in reveal1
- **v10**: missing status check in win
- **v11**: winner computation depends on block.timestamp
- **v12**: no preimage verification in reveal0
- **v13**: no preimage verification in reveal1
- **v14**: owner can force winner selection
- **v15**: redeem0_noreveal1 checks end_join instead of end_reveal1
- **v16**: reveal0() does not update status
- **v17**: `reveal1` does not update status
- **v18**: redeem*() functions send ETH to msg.sender
- **v19**: join1() does not require to match bet of player0
- **v20**: win() transfers ETH balance to msg.sender
- **v21**: `reveal0` has no upper deadline
- **v22**: `reveal1` has no upper deadline

## Verification data

- [Ground truth](ground-truth.csv)
- [Solcmc/z3](solcmc-z3.csv)
- [Solcmc/Eldarica](solcmc-eld.csv)
- [Certora](certora.csv)

## Experiments
