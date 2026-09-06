/// @custom:property donation-dos
/// @custom:description If the token balances of the contract exceed its reserves, a `redeem` transaction by a sender possessing a positive amount of liquidity tokens never reverts.

rule donation_dos {

    env e;
    uint maxValue = 1000000000000000000000000000;

    require(currentContract.getBalance0(e) > currentContract.r0(e));
    require(currentContract.getBalance1(e) > currentContract.r1(e));
    

    // Valid user and state of contract
    uint shares = currentContract.minted(e, e.msg.sender);
    require(shares > 0);
    require(shares <= currentContract.supply(e));
    require(currentContract.supply(e) > 0);


    // Overflow guard
    require(currentContract.getBalance0(e) < maxValue);
    require(currentContract.getBalance1(e) < maxValue);
    require(shares < maxValue);
    require(currentContract.supply(e) < maxValue);
    require(currentContract.r0(e) < maxValue);
    require(currentContract.r1(e) < maxValue);
    require(currentContract.getUserBalance0(e, e.msg.sender) < maxValue);
    require(currentContract.getUserBalance1(e, e.msg.sender) < maxValue);


    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.t0(e) != 0 && currentContract.t1(e) != 0);
    require(currentContract.t0(e) != currentContract && currentContract.t1(e) != currentContract);

    // Reentrancy
    


    // Tokens redeemed > 0
    require((shares * currentContract.r0(e)) / currentContract.supply(e) > 0);
    require((shares * currentContract.r1(e)) / currentContract.supply(e) > 0);

    
    require(e.msg.value == 0);
    require(e.msg.sender != 0);
    require(e.msg.sender != currentContract);


    redeem@withrevert(e, shares);

    assert(!lastReverted);
}
