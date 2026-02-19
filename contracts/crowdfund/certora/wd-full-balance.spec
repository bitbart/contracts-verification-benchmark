
/// wd-full-balance:
/// after a non-reverting `withdraw`,
/// the whole balance of the contract is sent to `owner`.

rule wd_full_balance {
    env e;
    
    require(nativeBalances[currentContract] >= currentContract.goal);
    require(e.block.number > currentContract.end_donate);
    require(e.msg.value == 0);

    mathint contract_old_balance = nativeBalances[currentContract];
    mathint owner_old_balance = nativeBalances[currentContract.owner];

    withdraw@withrevert(e);

    mathint contract_new_balance = nativeBalances[currentContract];
    mathint owner_new_balance = nativeBalances[currentContract.owner];

    assert !lastReverted =>
    e.msg.sender == currentContract.owner =>
    owner_new_balance == owner_old_balance + contract_old_balance && contract_new_balance == 0;
}


