// SPDX-License-Identifier: GPL-3.0-only

// After a non-reverting `redeem0_noreveal1` transaction the contract balance is zero.

rule deadlock_freedom_reveal1_witness {
    env e;

    redeem0_noreveal1(e);

    assert nativeBalances[currentContract] == 0;
}