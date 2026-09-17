// SPDX-License-Identifier: GPL-3.0-only

// After a non-reverting `redeem0_nojoin1` transaction the contract balance is zero

rule deadlock_freedom_join1_witness {
    env e;

    redeem0_nojoin1(e);

    assert nativeBalances[currentContract] == 0;
}
