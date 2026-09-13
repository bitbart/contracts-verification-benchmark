/// @custom:property redeem-precision
/// @custom:description After a non-reverting `redeem` transaction of a strictly positive amount of liquidity tokens, the real token balances of the sender strictly increase.

rule redeem_precision {
    env e;
    uint shares;
    
    require(shares > 0);
    require(shares <= currentContract.minted(e, e.msg.sender));
    require(shares <= currentContract.supply(e));
    require(currentContract.supply(e) > 0);

    // token validation
    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.t0(e) != 0 && currentContract.t1(e) != 0);
    require(currentContract.t0(e) != currentContract && currentContract.t1(e) != currentContract);
    

    // e.msg.sender validation
    require(e.msg.value == 0);
    require(e.msg.sender != 0);
    require(e.msg.sender != currentContract);
    require(e.msg.sender != currentContract.t0(e) && e.msg.sender != currentContract.t1(e));

    uint balance0Before = currentContract.getUserBalance0(e, e.msg.sender);
    uint balance1Before = currentContract.getUserBalance1(e, e.msg.sender);

    redeem(e, shares);

    uint balance0After = currentContract.getUserBalance0(e, e.msg.sender);
    uint balance1After = currentContract.getUserBalance1(e, e.msg.sender);

    assert(balance0After > balance0Before);
    assert(balance1After > balance1Before);
}
