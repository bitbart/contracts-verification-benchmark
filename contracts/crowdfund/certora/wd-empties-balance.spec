
/// wd-empties-balance:
/// after a non-reverting `withdraw`,
/// the ETH balance of the Crowdfund contract is equal to zero.


rule wd_empties_balance {
    env e;
    calldataarg args;
    
    require(e.block.number > currentContract.end_donate);
    require(nativeBalances[currentContract] >= currentContract.goal);
    require(e.msg.value == 0);

    withdraw@withrevert(e, args);

    assert !lastReverted => nativeBalances[currentContract] == 0;
}