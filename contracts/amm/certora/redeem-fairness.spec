/// @custom:property redeem-fairness
/// @custom:description After a non-reverting `redeem(x)` transaction, the balances of tokens `t0` and `t1` held by the sender must increase respectively by exactly `(x * b0) / supply` and `(x * b1) / supply`, where `b0` and `b1` are the contract's actual token balances before the transaction.

rule redeem_fairness {
    env e;
    uint x;


    require(currentContract.t0(e) != currentContract.t1(e));
    require(e.msg.sender != currentContract);


    uint supply = currentContract.supply(e);
    require(supply > 0);
    
    uint b0 = currentContract.t0(e).balanceOf(e, currentContract);
    uint b1 = currentContract.t1(e).balanceOf(e, currentContract);

    uint userB0Before = currentContract.t0(e).balanceOf(e, e.msg.sender);
    uint userB1Before = currentContract.t1(e).balanceOf(e, e.msg.sender);


    mathint expectedB0 = (x * b0) / supply;
    mathint expectedB1 = (x * b1) / supply;


    redeem(e, x);


    uint userB0After = currentContract.t0(e).balanceOf(e, e.msg.sender);
    uint userB1After = currentContract.t1(e).balanceOf(e, e.msg.sender);

    assert(userB0After - userB0Before == expectedB0);
    assert(userB1After - userB1Before == expectedB1);
}
