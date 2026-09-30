/// @custom:property swap-slippage
/// @custom:description After a non-reverting `swap(t, x_in, x_out_min)` transaction, the amount of token `t` transferred to the sender is greater than or equal to `x_out_min`.

rule swap_slippage {
    env e;
    address t;
    uint xIn;
    uint xOutMin;

    require(e.msg.sender != 0);
    require(e.msg.sender != currentContract);


    bool is_t0 = t == currentContract.t0(e);

    uint balanceOutBefore = is_t0 ? currentContract.t1(e).balanceOf(e, e.msg.sender) : currentContract.t0(e).balanceOf(e, e.msg.sender);

    swap(e, t, xIn, xOutMin);

    uint balanceOutAfter = is_t0 ? currentContract.t1(e).balanceOf(e, e.msg.sender) : currentContract.t0(e).balanceOf(e, e.msg.sender);
    

    assert(balanceOutAfter - balanceOutBefore >= xOutMin);
}
