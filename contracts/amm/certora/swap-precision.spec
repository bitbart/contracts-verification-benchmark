/// @custom:property swap-precision
/// @custom:description After a non-reverting `swap` transaction where `amountIn` is strictly positive and the minimum return is set to zero, the contract's balance of the output token is decreased.

rule swap_precision {
    env e;

    address token;
    uint amountIn;
    mathint balanceOutBefore;
    
    // token validation
    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.t0(e) != 0 && currentContract.t1(e) != 0);
    require(currentContract.t0(e) != currentContract && currentContract.t1(e) != currentContract);
    

    
    require(token == currentContract.t0(e) || token == currentContract.t1(e));
    require(amountIn > 0);
    

    if (token == currentContract.t0(e)) {
        balanceOutBefore = currentContract.getBalance1(e);
    }
    else {
        balanceOutBefore = currentContract.getBalance0(e);
    }

    swap(e, token, amountIn, 0);

    mathint balanceOutAfter;

    if (token == currentContract.t0(e)) {
        balanceOutAfter = currentContract.getBalance1(e);
    }
    else {
        balanceOutAfter = currentContract.getBalance0(e);
    }
    
    assert(balanceOutBefore - balanceOutAfter > 0);
}
