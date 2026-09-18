// SPDX-License-Identifier: GPL-3.0-only

// After a non-reverting `redeem0_nojoin1` transaction, assuming `player0`  and `player1` are EOAs, the contract balance is zero

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery versions/lib/EOA0.sol versions/lib/EOA1.sol --verify Lottery:certora/deadlock-freedom-join1-witness-eoa.spec --link Lottery:player0=EOA0 --link Lottery:player1=EOA1
rule deadlock_freedom_join1_witness_eoa {
    env e;
    
    redeem0_nojoin1(e);

    assert nativeBalances[currentContract] == 0;
}
