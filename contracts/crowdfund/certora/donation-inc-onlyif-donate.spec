
/// donation-inc-onlyif-donate:
/// if `donation[A]` is increased after a transaction (of the Crowdfund contract),
/// then that transaction must be a `donate` where A is the sender.

rule donation_inc_onlyif_donate {
    env e;
    calldataarg args;
    method f;
    address _user;
    
    mathint old_donation = currentContract.donation[_user];

    f(e, args);

    mathint new_donation = currentContract.donation[_user];
    
    assert(old_donation < new_donation => f.selector == sig:donate().selector && _user == e.msg.sender);
}

