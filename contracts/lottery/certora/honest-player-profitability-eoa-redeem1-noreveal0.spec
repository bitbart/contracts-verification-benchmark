// SPDX-License-Identifier: GPL-3.0-only

// Assuming `player0` and `player1` behave as EOAs: in state `Reveal0`, a user can perform a non-reverting
// transaction, made after the state's respective deadline, that strictly increases `player1`'s ETH balance
// by exactly the pot, leaves the contract's ETH balance at zero, and advances status to `End`

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery versions/lib/EOA0.sol versions/lib/EOA1.sol --verify Lottery:certora/honest-player-profitability-eoa-redeem1-noreveal0.spec --link Lottery:player0=EOA0 --link Lottery:player1=EOA1
rule honest_player_profitability_eoa_redeem1_noreveal0 (method f)
filtered {
    f -> !f.isView &&
         !f.isPure &&
         f.contract == currentContract
} {
    env e;
    calldataarg args;
    
    address p1  = currentContract.player1;
    require p1 != currentContract;

    mathint bet = currentContract.bet_amount;
    require bet >= MINIMUM_BET(e);
    mathint pot = bet * 2;

    mathint p1_bal_pre       = nativeBalances[p1];
    mathint contract_bal_pre = nativeBalances[currentContract];

    require currentContract.status == Lottery.Status.Reveal0;
    require e.block.number > currentContract.end_reveal0;
    require contract_bal_pre == pot;

    f(e, args);

    satisfy (
        nativeBalances[p1] == p1_bal_pre + pot &&
        nativeBalances[currentContract] == 0 &&
        currentContract.status == Lottery.Status.End
    );
}
