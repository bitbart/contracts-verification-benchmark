// SPDX-License-Identifier: GPL-3.0-only

// After a non-reverting `redeem1_noreveal0` transaction the contract balance is zero

rule deadlock_freedom_reveal0_witness {
    env e;

    redeem1_noreveal0(e);

    assert nativeBalances[currentContract] == 0;
}
