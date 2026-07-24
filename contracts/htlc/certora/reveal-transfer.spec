// SPDX-License-Identifier: GPL-3.0-only

// If `reveal()` is successful, `owner`'s balance must increase by at least the balance of the contract

rule reveal_transfer {
    env e;
    string s;

    mathint pre_contract_bal = nativeBalances[currentContract];

    address owner = currentContract.owner;  
    require currentContract != owner;  
    mathint pre_owner_bal = nativeBalances[owner];

    reveal@withrevert(e, s);

    require !lastReverted;
    assert (nativeBalances[owner] >= pre_owner_bal + pre_contract_bal);
}
