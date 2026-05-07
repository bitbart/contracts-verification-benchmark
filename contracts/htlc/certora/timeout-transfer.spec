rule timeout_transfer {
    env e;

    mathint pre_contract_bal = nativeBalances[currentContract];
    address verifier = currentContract.verifier;
    mathint pre_verifier_bal = nativeBalances[verifier];
    
    address owner = currentContract.owner;
    mathint pre_owner_bal = nativeBalances[owner];

    require verifier != owner, "verifier and owner should be different";

    timeout(e);

    assert nativeBalances[verifier] >= pre_verifier_bal;
}

// counter example, a contract that transfer the amount on receive