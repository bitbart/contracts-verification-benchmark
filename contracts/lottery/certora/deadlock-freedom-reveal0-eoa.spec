// SPDX-License-Identifier: GPL-3.0-only

// In state `Reveal0` if contract balance is positive, some user can perform,
// either immediately, or in the future provided there are no in-between
// transactions, a non-reverting transaction that empties the contract balance,
// assuming that `player0` and `player1` are EOAs.

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery versions/lib/EOA0.sol versions/lib/EOA1.sol --verify Lottery:certora/deadlock-freedom-reveal0-eoa.spec --link Lottery:player0=EOA0 --link Lottery:player1=EOA1 --optimistic_hashing --optimistic_loop

/// @custom:negate
rule deadlock_freedom_reveal0_eoa (method f)
filtered {
    f -> !f.isView && !f.isPure
} {
    env e;
    calldataarg args;

    require nativeBalances[currentContract] > 0;
    require status(e) == Lottery.Status.Reveal0;

    f(e, args);

    assert nativeBalances[currentContract] != 0;
}
