
/// wd-not-revert-EOA:
/// a transaction `withdraw` is not reverted if
/// the contract balance is greater than or equal to the goal,
/// the donation phase has ended, and
/// the `receiver` is an EOA.


hook CALL(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
    require rc == 1;
}

rule wd_not_revert_EOA {
    env e;
    calldataarg args;
    
    // require(!_reentrancyGuardEntered(e));

    require(e.block.number > currentContract.end_donate);
    require(nativeBalances[currentContract] >= currentContract.goal);
    require(e.msg.value == 0);
    
    withdraw@withrevert(e, args);


    assert !lastReverted;
}