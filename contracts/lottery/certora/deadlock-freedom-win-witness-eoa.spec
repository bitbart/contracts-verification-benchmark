// SPDX-License-Identifier: GPL-3.0-only

// After a non-reverting `win` transaction, assuming both `player0` and `player1` are EOAs, the contract balance is zero

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery versions/lib/EOA0.sol versions/lib/EOA1.sol --verify Lottery:certora/deadlock-freedom-win-witness-eoa.spec --link Lottery:player0=EOA0 --link Lottery:player1=EOA1 --optimistic_loop

rule deadlock_freedom_win_witness_eoa {
    env e;
    
    win(e);

    assert nativeBalances[currentContract] == 0;
}