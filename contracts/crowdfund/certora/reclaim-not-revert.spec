/// reclaim-not-revert:
/// a transaction `reclaim` is not reverted if
/// the goal amount is not reached and
/// the deposit phase has ended, and
/// the sender has donated funds that they have not reclaimed yet.

rule reclaim_not_revert {
    env e;
    
    require(nativeBalances[currentContract] < currentContract.goal);
    require(e.block.number > currentContract.end_donate);
    require(currentContract.donation[e.msg.sender] > 0);
    require(e.msg.value == 0);
    
    reclaim@withrevert(e);    

    assert !lastReverted;
}

