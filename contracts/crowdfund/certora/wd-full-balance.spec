
/// wd-full-balance:
/// after a non-reverting `withdraw`,
/// the whole balance of the contract is sent to `owner`.

rule wd_full_balance {
    env e;
    calldataarg args;
    
    require(e.block.number > currentContract.end_donate);
    require(nativeBalances[currentContract] >= currentContract.goal);
    
    require(e.msg.value == 0);

    mathint contract_old_balance = nativeBalances[currentContract];
    mathint owner_old_balance = nativeBalances[currentContract.owner];

    withdraw@withrevert(e, args);

    mathint contract_new_balance = nativeBalances[currentContract];
    mathint owner_new_balance = nativeBalances[currentContract.owner];

    assert !lastReverted => owner_new_balance == owner_old_balance + contract_old_balance && contract_new_balance == 0;
}


