/// donate-not-revert:
/// a transaction `donate` is not reverted if
/// the donation phase has not ended.

rule donate_not_revert {
    env e;
    
    require(e.block.number <= currentContract.end_donate);
    require(e.msg.value <= nativeBalances[e.msg.sender]);

    donate@withrevert(e);    

    assert !lastReverted;
}

