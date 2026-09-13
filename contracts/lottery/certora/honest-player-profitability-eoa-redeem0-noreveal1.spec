// SPDX-License-Identifier: GPL-3.0-only

// Assuming `player0` and `player1` behave as EOAs: in state `Reveal1`, a user can perform a non-reverting
// transaction, made after the state's respective deadline, that strictly increases `player0`'s ETH balance
// by exactly the pot, leaves the contract's ETH balance at zero, and advances status to `End`

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery versions/lib/EOA0.sol versions/lib/EOA1.sol --verify Lottery:certora/honest-player-profitability-eoa-redeem0-noreveal1.spec --link Lottery:player0=EOA0 --link Lottery:player1=EOA1
rule honest_player_profitability_eoa_redeem0_noreveal1 (method f)
filtered {
    f -> !f.isView &&
         !f.isPure &&
         f.contract == currentContract
} {
    env e;
    calldataarg args;

    address p0  = currentContract.player0;
    require p0 != currentContract;

    mathint bet = currentContract.bet_amount;
    require bet >= MINIMUM_BET(e);
    mathint pot = bet * 2;

    mathint p0_bal_pre       = nativeBalances[p0];
    mathint contract_bal_pre = nativeBalances[currentContract];

    require currentContract.status == Lottery.Status.Reveal1;
    require e.block.number > currentContract.end_reveal1;
    require contract_bal_pre == pot;

    f(e, args);

    satisfy (
        nativeBalances[p0] == p0_bal_pre + pot &&
        nativeBalances[currentContract] == 0 &&
        currentContract.status == Lottery.Status.End
    );
}
