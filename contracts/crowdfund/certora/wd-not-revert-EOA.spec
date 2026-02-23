/// EDITING STILL IN PROGRESS
/// TO DO: To check whether all unrealistic scenarios are ruled out


/// wd-not-revert-EOA:
/// a transaction `withdraw` is not reverted if
/// the contract balance is greater than or equal to the goal,
/// the donation phase has ended, and
/// the `receiver` is an EOA.

rule wd_not_revert_EOA {
    env e;
    
    require(nativeBalances[currentContract] >= currentContract.goal);
    require(e.block.number > currentContract.end_donate);
    require(e.msg.value == 0);
    require(e.msg.sender == e.tx.origin);

    // _status is a flag in ReentrancyGuard.sol
    // _status = 1 implies no nonReentrant function is currently executing
    // require(currentContract._status == 1);

    // trivial checks to rule out unrealistic scenarios
    require(e.block.number != max_uint256);
    require(nativeBalances[currentContract.owner] < max_uint - nativeBalances[currentContract]);
    require(e.msg.sender != currentContract);
    require(e.msg.sender != 0 && e.tx.origin != 0);
    // require(nativeCodesize[currentContract.owner] == 0);
    require(nativeBalances[currentContract] != 0);
    require(currentContract.end_donate > 1);

//    mathint contract_old_bal = nativeBalances[currentContract];
//    mathint owner_old_bal = nativeBalances[currentContract.owner];
    
    withdraw@withrevert(e);    

//    mathint contract_new_bal = nativeBalances[currentContract];
//    mathint owner_new_bal = nativeBalances[currentContract.owner];

    assert !lastReverted;
}