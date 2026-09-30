/// @custom:property constant-product
/// @custom:description After a non-reverting `swap` transaction, the product of the contract's token balances is greater than or equal to the product before the transaction.

rule constant_product {
    env e;
    address t;
    uint xIn;
    uint xOutMin;

    mathint kBefore = currentContract.t0(e).balanceOf(e, currentContract) * currentContract.t1(e).balanceOf(e, currentContract);


    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.t0(e) != 0 && currentContract.t1(e) != 0);
    require(currentContract.t0(e) != currentContract && currentContract.t1(e) != currentContract);    
    
    require(t == currentContract.t0(e) || t == currentContract.t1(e));
    require(xIn > 0);


    swap(e, t, xIn, xOutMin);


    mathint kAfter = currentContract.t0(e).balanceOf(e, currentContract) * currentContract.t1(e).balanceOf(e, currentContract);


    assert(kAfter >= kBefore);
}