
/// donation-inc-onlyif-donate:
/// if `donation[A]` is increased after a transaction (of the Crowdfund contract),
/// then that transaction must be a `donate` where A is the sender.

rule donation_inc_onlyif_donate {
    env e;
    calldataarg args;
    method f;
    
    mathint old_donation = currentContract.donation[e.msg.sender];

    f(e, args);

    mathint new_donation = currentContract.donation[e.msg.sender];
    
    assert e.block.number <= currentContract.end_donate =>
    old_donation < new_donation =>
    f.selector == sig:donate().selector;
}

