/// bal-decr-onlyif-wd-reclaim:
/// after the donation phase, if the contract balance decreases then
/// either a successful `withdraw` or `reclaim` have been performed.

rule bal_decr_onlyif_wd_reclaim {
    env e;
    calldataarg args;
    method f;
    
    require(e.block.number > currentContract.end_donate);
    
    mathint old_balance = nativeBalances[currentContract];

    f(e, args);

    mathint new_balance = nativeBalances[currentContract];
    
    assert old_balance > new_balance => (
        f.selector == sig:withdraw().selector ||
        f.selector == sig:reclaim().selector
    );

    
}

