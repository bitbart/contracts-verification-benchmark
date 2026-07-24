
/// reclaim-even-if-msgvalue:
/// for a call to `reclaim` by `msg.sender` A, the call executes
/// as expected even if `msg.value` is non-zero.

rule reclaim_even_if_msgvalue {
    env e;

    require(e.block.number > currentContract.end_donate);
    require(nativeBalances[currentContract] < currentContract.goal);
    require(currentContract.donation[e.msg.sender] > 0);
    
    require(e.msg.value > 0);

    reclaim@withrevert(e);

    assert !lastReverted;
}