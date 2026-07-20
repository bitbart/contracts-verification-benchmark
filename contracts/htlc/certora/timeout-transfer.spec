// SPDX-License-Identifier: GPL-3.0-only

// If `timeout()` is successfully called, `verifier`'s balance must increase by at least the balance of the contract

rule timeout_transfer {
    env e;

    mathint pre_contract_bal = nativeBalances[currentContract];
    
    address verifier = currentContract.verifier;
    require currentContract != verifier;
    mathint pre_verifier_bal = nativeBalances[verifier];
    
    timeout@withrevert(e);
    
    require !lastReverted;
    assert (nativeBalances[verifier] >= pre_verifier_bal + pre_contract_bal);
}