/// wd-not-revert:
/// a transaction `withdraw` is not reverted if
/// the contract balance is greater than or equal to the goal and
/// the donation phase has ended.

rule wd_not_revert {
    env e;
    
    require(nativeBalances[currentContract] >= currentContract.goal);
    require(e.block.number > currentContract.end_donate);
    require(e.msg.value == 0);
    
    withdraw@withrevert(e);   

    assert !lastReverted;
}