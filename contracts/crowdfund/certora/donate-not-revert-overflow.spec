/// donate-not-revert-overflow:
/// a transaction `donate` is not reverted if
/// the donation phase has not ended and
/// sum between the old and the current donation does not overflow.

rule donate_not_revert_overflow {
    env e;
    
    require(e.block.number <= currentContract.end_donate);
    require(e.msg.value <= nativeBalances[e.msg.sender]);
    mathint n = currentContract.donation[e.msg.sender];

    require(n < max_uint - e.msg.value);

    donate@withrevert(e);

    assert !lastReverted;
}
