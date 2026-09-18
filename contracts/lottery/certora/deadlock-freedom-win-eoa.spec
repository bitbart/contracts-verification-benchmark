// SPDX-License-Identifier: GPL-3.0-only

// In state `Win` if contract balance is positive, some user can perform,
// either immediately, or in the future provided there are no in-between
// transactions, a non-reverting transaction that empties the contract balance,
// assuming that `player0` and `player1` are both EOAs.

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery versions/lib/EOA0.sol versions/lib/EOA1.sol --verify Lottery:certora/deadlock-freedom-win-eoa.spec --link Lottery:player0=EOA0 --link Lottery:player1=EOA1 --optimistic_loop

/// @custom:negate
rule deadlock_freedom_win_eoa (method f)
filtered {
    f -> !f.isView && !f.isPure
} {
    env e;
    calldataarg args;
    
    require nativeBalances[currentContract] > 0;
    require status(e) == Lottery.Status.Win;

    f(e, args);

    assert nativeBalances[currentContract] != 0;
}