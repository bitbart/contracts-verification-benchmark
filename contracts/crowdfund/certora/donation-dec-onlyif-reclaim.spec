
/// donation-dec-onlyif-reclaim:
/// if `donation[A]` decreases after a transaction (of the Crowdfund contract),
/// then that transaction must be a `reclaim` where A is the sender.

rule donation_dec_onlyif_reclaim {
    env e;
    calldataarg args;
    method f;
    
    mathint donation_prev = currentContract.donation[e.msg.sender];

    f(e, args);

    mathint donation_next = currentContract.donation[e.msg.sender];
    
    assert e.block.number <= currentContract.end_donate =>
    donation_next < donation_prev =>
    f.selector == sig:reclaim().selector;
}

