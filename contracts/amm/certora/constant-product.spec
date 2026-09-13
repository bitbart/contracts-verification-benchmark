/// @custom:property constant-product
/// @custom:description After a non-reverting `swap` transaction, the product of the contract's token balances is greater than or equal to the product before the transaction.

rule constant_product {
    env e;

    // Preconditions
    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.t0(e) != 0 && currentContract.t1(e) != 0);
    require(currentContract.t0(e) != currentContract && currentContract.t1(e) != currentContract);
    
    mathint oldK = currentContract.getBalance0(e) * currentContract.getBalance1(e);

    address token;
    uint amountIn;
    uint amountOutMin;
    
    require(token == currentContract.t0(e) || token == currentContract.t1(e));
    require(amountIn > 0);
    
    swap(e, token, amountIn, amountOutMin);

    mathint newK = currentContract.getBalance0(e) * currentContract.getBalance1(e);

    assert(newK >= oldK);
}
