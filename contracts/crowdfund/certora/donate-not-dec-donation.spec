
/// donate-not-dec-donation:
///  after a non-reverting `donate` transaction by user A,
/// `donation[A]` is not decreased.

rule donate_not_dec_donation {
    env e;
    
    require(e.block.number <= currentContract.end_donate);
    require(e.msg.value <= nativeBalances[e.msg.sender]);

    mathint donor_prev = currentContract.donation[e.msg.sender];

    donate@withrevert(e);   

    mathint donor_next = currentContract.donation[e.msg.sender];

    assert !lastReverted =>
    donor_next >= donor_prev;
}

