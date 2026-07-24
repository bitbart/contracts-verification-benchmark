
/// wd-onlyif-goal-reached:
/// after a non-reverting `withdraw`, the balance of the contract before the 
/// transaction must have been greater or equal to the `goal`.

rule wd_onlyif_goal_reached {
    env e;
    calldataarg args;

    require(e.block.number > currentContract.end_donate);
    require(e.msg.value == 0);

    mathint balanceBefore = nativeBalances[currentContract];

    withdraw@withrevert(e, args);

    assert((!lastReverted) => balanceBefore >= currentContract.goal);

}