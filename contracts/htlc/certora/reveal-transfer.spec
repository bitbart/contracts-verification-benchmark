// SPDX-License-Identifier: GPL-3.0-only

// When reveal is successfully called, all the balance should be transferred to
// the owner

rule reveal_transfer {
    env e;
    string s;
    mathint pre_contract_bal = nativeBalances[currentContract];
    address owner = currentContract.owner;    
    mathint pre_owner_bal = nativeBalances[owner];

    reveal@withrevert(e, s);

    // does not hold
    // assert nativeBalances[owner] > pre_owner_bal; //+ pre_contract_bal; // && nativeBalances[currentContract] == 0;
    // holds
    // assert nativeBalances[owner] >= pre_owner_bal;
    require !lastReverted;
    assert (
        nativeBalances[owner] == pre_owner_bal + pre_contract_bal
    );
}
