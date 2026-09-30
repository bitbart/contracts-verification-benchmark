/// @custom:property redeem-precision
/// @custom:description Let `b0B`, `b1B` be the token balances of the sender before the transaction, and let `b0A` and `b1A` be the token balances of the sender after the transaction. After a non-reverting `redeem(x)` transaction, with `x > 0`, then `b0A > b0B` and `b1A > b1B`.

rule redeem_precision {
    env e;
    uint x;

    require(e.msg.value == 0);
    require(e.msg.sender != 0);


    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.t0(e) != 0 && currentContract.t1(e) != 0);
    require(e.msg.sender != currentContract);
    require(e.msg.sender != currentContract.t0(e) && e.msg.sender != currentContract.t1(e));

    require(currentContract.supply(e) > 0);
    require(currentContract.minted(e, e.msg.sender) >= x);
    require(x < currentContract.supply);

    uint b0 = currentContract.t0(e).balanceOf(e, e.msg.sender);
    uint b1 = currentContract.t1(e).balanceOf(e, e.msg.sender);

    redeem(e, x);

    uint b0A = currentContract.t0(e).balanceOf(e, e.msg.sender);
    uint b1A = currentContract.t1(e).balanceOf(e, e.msg.sender);

    assert(b0A > b0);
    assert(b1A > b1);
}
