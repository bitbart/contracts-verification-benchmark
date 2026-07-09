
/// goal-not-change:
/// the value of `goal` does not change after its value is
/// initialized in the constructor.

rule goal_not_change {

    env e;
    calldataarg args;
    method f;

    mathint old_goal = currentContract.goal;


    f@withrevert(e, args);

    mathint new_goal = currentContract.goal;

    assert old_goal == new_goal;
    
}