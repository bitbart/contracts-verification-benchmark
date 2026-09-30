/// @custom:property swap-fee
/// @custom:description After a non-reverting `swap(t0, x_in, x_out_min)` transaction, with `r0 > 0` and `r1 > 0`, the product of the contract's internal reserves `r0` and `r1` after the transaction is greater than their product before the transaction.

rule swap_fee_gt0 {

    env e;
    address t;
    uint xIn;
    uint xMin;

    // require(currentContract.t0(e) != currentContract.t1(e));
    require(e.msg.sender != currentContract);
    require(e.msg.sender != 0);

    require(t == currentContract.t0(e) || t == currentContract.t1(e));
    require(xIn > 0);

    mathint kBefore = currentContract.r0(e) * currentContract.r1(e);

    require(kBefore > 0);

    swap(e, t, xIn, xMin);

    mathint kAfter = currentContract.r0(e) * currentContract.r1(e);

    assert(kAfter > kBefore);
}
