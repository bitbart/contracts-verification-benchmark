/// @custom:property redeem-liveness
/// @custom:description Let `b0`, `b1` be the token balances of the contract, and let `r0`, `r1` be the internal reserves of the contract. If `r0 == b0` and `r1 == b1`, a `redeem(x)` transaction by a sender `A`, with `minted[A] >= x`, `x > 0` and `x < supply` never reverts.

rule redeem_liveness {
    env e;
    uint x;
    
    require(e.msg.value == 0);
    require(e.msg.sender != 0);
    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.t0(e) != 0 && currentContract.t1(e) != 0);


    require(currentContract.t0(e).balanceOf(e, currentContract) == currentContract.r0(e));
    require(currentContract.t1(e).balanceOf(e, currentContract) == currentContract.r1(e));


    require(currentContract.minted(e, e.msg.sender) >= x);
    require(x > 0);
    require(x < currentContract.supply(e));


    // Remove??
    // require(currentContract.unlocked(e) == 1);
    // require(currentContract.r0(e) <= 1000000000000000000000000000000000000);
    // require(currentContract.r1(e) <= 1000000000000000000000000000000000000);
    // require(currentContract.supply(e) <= 1000000000000000000000000000000000000);
    // require(currentContract.t0(e).balanceOf(e, e.msg.sender) <= 1000000000000000000000000000000000000);
    // require(currentContract.t1(e).balanceOf(e, e.msg.sender) <= 1000000000000000000000000000000000000);
    // require(currentContract.supply(e) > 0);


    redeem@withrevert(e, x);

    assert(!lastReverted);
}
