// SPDX-License-Identifier: GPL-3.0-only

// Assuming `player0` and `player1` behave as EOAs: in state `Join1`, a user can perform a non-reverting
// transaction, made after the state's respective deadline, that strictly increases `player0`'s ETH balance
// by exactly their bet, leaves the contract's ETH balance at zero, and advances state to `End`

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery versions/lib/EOA0.sol versions/lib/EOA1.sol --verify Lottery:certora/honest-player-profitability-eoa-redeem0-nojoin1.spec --link Lottery:player0=EOA0 --link Lottery:player1=EOA1
rule honest_player_profitability_eoa_redeem0_nojoin1 (method f)
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
    
    mathint p0_bal_pre       = nativeBalances[p0];
    mathint contract_bal_pre = nativeBalances[currentContract];

    require currentContract.status == Lottery.Status.Join1;
    require e.block.number > currentContract.end_join;
    require contract_bal_pre  == bet;

    f(e, args);

    satisfy (
        nativeBalances[p0] == p0_bal_pre + bet &&
        nativeBalances[currentContract] == 0 &&
        currentContract.status == Lottery.Status.End
    );
}
