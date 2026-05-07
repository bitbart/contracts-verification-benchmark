
/// donate-bal-inc:
/// a non-reverting call to `donate` 
/// does not decrease the balance of the contract.

rule donate_bal_inc {
    env e;
    
    require(e.block.number <= currentContract.end_donate);
    require(e.msg.value <= nativeBalances[e.msg.sender]);

    mathint old_balance = nativeBalances[currentContract];

    donate@withrevert(e);

    mathint new_balance = nativeBalances[currentContract];

    assert !lastReverted => old_balance <= new_balance;

}