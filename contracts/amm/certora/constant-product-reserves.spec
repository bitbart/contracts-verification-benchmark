/// @custom:property constant-product-reserves
/// @custom:description After a non-reverting `swap(t, x_in, x_out_min)` transaction, the product between `r0` and `r1` after the transaction is greater than or equal to their product before the transaction, where `r0` and `r1` are the token internal reserves of the contract.

rule constant_product_reserves {

    env e;
    address t;
    uint xIn;
    uint xOutMin;

    mathint kBefore = currentContract.r0(e) * currentContract.r1(e);


    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.t0(e) != 0 && currentContract.t1(e) != 0);
    require(currentContract.t0(e) != currentContract && currentContract.t1(e) != currentContract);    
    
    require(t == currentContract.t0(e) || t == currentContract.t1(e));
    require(xIn > 0);


    swap(e, t, xIn, xOutMin);


    mathint kAfter = currentContract.r0(e) * currentContract.r1(e);


    assert(kAfter >= kBefore);
}
