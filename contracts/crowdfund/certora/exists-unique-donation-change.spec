
/// exists-unique-donation-change:
/// after a non-reverting `donate` transaction to the Crowdfund contract,
/// the donation of exactly one user has changed.

rule exists_unique_donation_change {
    env e;
    address a;
    require a != e.msg.sender;

    require(e.block.number <= currentContract.end_donate);
    require(e.msg.value <= nativeBalances[e.msg.sender]);

    mathint non_donor_prev = currentContract.donation[a];

    donate@withrevert(e);    

    mathint non_donor_next = currentContract.donation[a];

    assert !lastReverted => non_donor_next == non_donor_prev;
}

