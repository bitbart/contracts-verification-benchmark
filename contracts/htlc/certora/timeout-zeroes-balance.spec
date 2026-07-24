// SPDX-License-Identifier: GPL-3.0-only

// If `timeout()` is successful, it must completely drain the contract's balance

rule timeout_zeroes_balance {
    env e;
    
    address verifier = currentContract.verifier;
    require currentContract != verifier;
    timeout(e);

    assert nativeBalances[currentContract] == 0;
}