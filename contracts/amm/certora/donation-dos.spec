/// @custom:property donation-dos
/// @custom:description Let `t0`, `t1` be the amount of token0 and token1 held by the contract, let `r0`, `r1` be the contract's internal reserves of those tokens, and let `supply` be the internal supply of the contract. If `b0 >= r0` and `b1 >= r1`, a `redeem(x)`, transaction by a sender A, with `minted[A] > x`, `supply > 0` and `x < supply` never reverts.

rule donation_dos {
    env e;
    uint x;

    require(currentContract.t0(e).balanceOf(e, currentContract) > currentContract.r0(e));
    require(currentContract.t1(e).balanceOf(e, currentContract) > currentContract.r1(e));
    
    require(currentContract.minted(e, e.msg.sender) >= x);
    require(currentContract.supply(e) > 0);
    require(x <= currentContract.supply(e));



    // Remove?
    // uint maxValue = 1000000000000000000000000000;
    // require(currentContract.t0(e).balanceOf(e, currentContract) < maxValue);
    // require(currentContract.t1(e).balanceOf(e, currentContract) < maxValue);
    // require(x < maxValue);
    // require(currentContract.supply(e) < maxValue);
    // require(currentContract.r0(e) < maxValue);
    // require(currentContract.r1(e) < maxValue);
    // require(currentContract.t0(e).balanceOf(e, e.msg.sender) < maxValue);
    // require(currentContract.t1(e).balanceOf(e, e.msg.sender) < maxValue);




    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.t0(e) != 0 && currentContract.t1(e) != 0);
    require(currentContract.t0(e) != currentContract && currentContract.t1(e) != currentContract);    
    require(e.msg.sender != currentContract);
    require(e.msg.sender != 0);
    require(e.msg.value == 0);



    redeem@withrevert(e, x);

    assert(!lastReverted);
}
