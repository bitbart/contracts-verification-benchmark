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