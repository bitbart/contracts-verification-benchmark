/// @custom:property reserves-not-drained
/// @custom:description If the tracked reserves of the contract are both strictly positive, then after any non-reverting transaction to the contract, the tracked reserves remain strictly positive.

rule reserves_not_drained(method f) {
    env e;
    calldataarg args;

    require(currentContract.r0(e) > 0 && currentContract.r1(e) > 0);
    require(currentContract.getBalance0(e) >= currentContract.r0(e));
    require(currentContract.getBalance1(e) >= currentContract.r1(e));

    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.supply(e) > 0);
    require(currentContract.minted(e, e.msg.sender) < currentContract.supply(e));

    f(e, args);

    assert(currentContract.r0(e) > 0 && currentContract.r1(e) > 0);
}
