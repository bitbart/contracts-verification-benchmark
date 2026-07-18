// SPDX-License-Identifier: GPL-3.0-only

// If `reveal()` is successfully called, it must completely drain the contract's balance

rule reveal_zeroes_balance {
    env e;
    string s;
    
    require currentContract.owner != currentContract;
    require nativeBalances[currentContract] == currentContract.fee;

    reveal@withrevert(e, s);

    require !lastReverted;

    assert nativeBalances[currentContract] == 0;
}