/// @custom:property swap-precision
/// @custom:description Let t0, t1 be two different tokens held by the contract. After a non-reverting `swap(t0, x_in, x_out_min)` transaction where `x_out_min == 0`, the contract's balance of `t1` is decreased.

rule swap_precision {
    env e;
    address token;
    uint xIn;
    uint xMin;

    require(e.msg.sender != currentContract);
    require(e.msg.sender != 0);


    require(token == currentContract.t0(e) || token == currentContract.t1(e));
    require(xIn > 0);
    
    mathint balanceOutBefore;

    if (token == currentContract.t0(e)) {
        balanceOutBefore = currentContract.t1(e).balanceOf(e, currentContract);
    }
    else {
        balanceOutBefore = currentContract.t0(e).balanceOf(e, currentContract);
    }

    
    swap(e, token, xIn, xMin);

    mathint balanceOutAfter;

    if (token == currentContract.t0(e)) {
        balanceOutAfter = currentContract.t1(e).balanceOf(e, currentContract);
    } else {
        balanceOutAfter = currentContract.t0(e).balanceOf(e, currentContract);
    }
    
    assert(balanceOutBefore > balanceOutAfter);
}
