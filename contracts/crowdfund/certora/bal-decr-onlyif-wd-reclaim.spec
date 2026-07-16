
/// bal-decr-onlyif-wd-reclaim:
/// after the donation phase, if the contract balance decreases then
/// either a successful `withdraw` or `reclaim` have been performed.

rule bal_decr_onlyif_wd_reclaim {
    env e;
    calldataarg args;
    method f;
    
    require(e.block.number > currentContract.end_donate);
    
    mathint old_balance = nativeBalances[currentContract];

    f@withrevert(e, args);

    mathint new_balance = nativeBalances[currentContract];
    

    // default version of the assertion
    assert (old_balance > new_balance && !lastReverted) => (
        f.selector == sig:withdraw().selector ||
        f.selector == sig:reclaim().selector
    );


    // v6 version of the assertion
    // assert (old_balance > new_balance && !lastReverted) => (
        // f.selector == sig:withdraw(address).selector ||
        // f.selector == sig:reclaim().selector
    // );

    // Obviously, if the call reverted then the balance should not have changed.
    assert lastReverted => old_balance == new_balance;
    
}

