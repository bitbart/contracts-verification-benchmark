/// @custom:property redeem-fairness
/// @custom:description After a non-reverting `redeem` transaction, the token balances of the sender must increase by an amount proportional to their fraction of the total supply, calculated against the contract's actual token balances.

rule redeem_fairness {
    env e;
    uint x;

    uint userMintedBefore = currentContract.minted(e, e.msg.sender);
    uint supplyBefore = currentContract.supply(e);

    // x belongs to (0; minted[msg.sender]]
    require(x > 0 && x <= userMintedBefore);

    // State of the contract
    require(supplyBefore > 0);
    require(userMintedBefore <= supplyBefore);
    

    uint bal0Before = currentContract.getBalance0(e);
    uint bal1Before = currentContract.getBalance1(e);

    uint userBal0Before = currentContract.getUserBalance0(e, e.msg.sender);
    uint userBal1Before = currentContract.getUserBalance1(e, e.msg.sender);

    mathint expectedOut0 = (x * bal0Before) / supplyBefore;
    mathint expectedOut1 = (x * bal1Before) / supplyBefore;

    // token validation
    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.t0(e) != 0 && currentContract.t1(e) != 0);
    require(currentContract.t0(e) != currentContract && currentContract.t1(e) != currentContract);

    // msg.sender validation
    require(e.msg.value == 0);
    require(e.msg.sender != 0);
    require(e.msg.sender != currentContract);
    require(e.msg.sender != currentContract.t0(e) && e.msg.sender != currentContract.t1(e));

    redeem(e, x);

    uint userBal0After = currentContract.getUserBalance0(e, e.msg.sender);
    uint userBal1After = currentContract.getUserBalance1(e, e.msg.sender);

    assert(userBal0After - userBal0Before == expectedOut0);
    assert(userBal1After - userBal1Before == expectedOut1);
}
