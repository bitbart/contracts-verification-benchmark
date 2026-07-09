
/// no-wd-if-no-goal:
/// calls to `withdraw` will revert if
/// the contract balance is less than the `goal`.

rule no_wd_if_no_goal {
    env e;
    calldataarg args;
    
    require nativeBalances[currentContract] < currentContract.goal;
    require(e.msg.value == 0);

    withdraw@withrevert(e, args);  
    assert lastReverted;
}

