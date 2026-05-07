/// no-wd-if-no-goal:
/// calls to `withdraw` will revert if
/// the contract balance is less than the `goal`.

rule no_wd_if_no_goal {
    env e;
    
    require nativeBalances[currentContract] < currentContract.goal;
    
    withdraw@withrevert(e);    
    assert lastReverted;
}

