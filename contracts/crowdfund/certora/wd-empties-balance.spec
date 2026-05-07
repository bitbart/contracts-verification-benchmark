
/// wd-empties-balance:
// after a non-reverting `withdraw`,
// the ETH balance of the Crowdfund contract is equal to zero.


rule wd_empties_balance {
    env e;
    
    require(nativeBalances[currentContract] >= currentContract.goal);
    require(e.block.number > currentContract.end_donate);
    require(e.msg.value == 0);

    withdraw@withrevert(e);

    mathint contract_new_balance = nativeBalances[currentContract];

    assert !lastReverted =>
    contract_new_balance == 0;
}