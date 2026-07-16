
/// donation-dec-onlyif-reclaim:
/// if `donation[A]` decreases after a transaction (of the Crowdfund contract),
/// then that transaction must be a `reclaim` where A is the sender.

rule donation_dec_onlyif_reclaim {
    env e;
    calldataarg args;
    method f;
    address _user;
    
    mathint donation_prev = currentContract.donation[_user];

    f(e, args);

    mathint donation_next = currentContract.donation[_user];
    
    assert donation_next < donation_prev => f.selector == sig:reclaim().selector && _user == e.msg.sender;
}

