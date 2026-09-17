// SPDX-License-Identifier: GPL-3.0-only

// After a non-reverting `win` transaction the contract balance is zero

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery --verify Lottery:certora/deadlock-freedom-win-witness.spec --optimistic_loop

rule deadlock_freedom_win_witness {
    env e;
    
    win(e);

    assert nativeBalances[currentContract] == 0;
}