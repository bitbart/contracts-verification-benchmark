/// @custom:property swap-fee
/// @custom:description After a non-reverting `swap` transaction, the product of the contract's tracked reserves strictly increases.

rule swap_fee(env e, address t, uint xIn, uint xOutMin) {

    mathint kBefore = currentContract.r0(e) * currentContract.r1(e);

    require(kBefore > 0);

    require(e.msg.sender != currentContract);
    require(currentContract.t0(e) != currentContract.t1(e));

    require(currentContract.getBalance0(e) >= currentContract.r0(e));
    require(currentContract.getBalance1(e) >= currentContract.r1(e));

    swap(e, t, xIn, xOutMin);

    mathint kAfter = currentContract.r0(e) * currentContract.r1(e);

    assert(kAfter > kBefore);
}
