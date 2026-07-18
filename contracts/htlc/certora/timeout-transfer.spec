// SPDX-License-Identifier: GPL-3.0-only

// If `timeout()` is successfully called, it must completely drain the contract's balance

// SEPARARE SVUOTAMENTO E TRASFERIMENTO???

// When `timeout` is successfully called, then all the balance should be
// transferred to the verifier

rule timeout_transfer {
    env e;

    mathint pre_contract_bal = nativeBalances[currentContract];
    address verifier = currentContract.verifier;
    mathint pre_verifier_bal = nativeBalances[verifier];
    
    address owner = currentContract.owner;
    mathint pre_owner_bal = nativeBalances[owner];

    require verifier != owner;

    timeout(e);
    
    assert (nativeBalances[verifier] >= pre_verifier_bal);
    assert (nativeBalances[currentContract] == 0);
}

// counter example, a contract that transfer the amount on receive