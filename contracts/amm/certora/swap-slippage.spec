/// @custom:property swap-slippage
/// @custom:description After a non-reverting `swap` transaction, the amount of output tokens transferred to the sender is greater than or equal to the minimum return requested.

rule swap_slippage(env e, address t, uint xIn, uint xOutMin) {
    require(e.msg.value == 0);
    require(e.msg.sender != 0);
    require(e.msg.sender != currentContract);

    // Token validation
    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.t0(e) != 0 && currentContract.t1(e) != 0);
    require(currentContract.t0(e) != currentContract && currentContract.t1(e) != currentContract);
    require(e.msg.sender != currentContract.t0(e) && e.msg.sender != currentContract.t1(e));

    require(t == currentContract.t0(e) || t == currentContract.t1(e));
    bool is_t0 = t == currentContract.t0(e);

    uint balanceOutBefore = is_t0 ? currentContract.getUserBalance1(e, e.msg.sender) : currentContract.getUserBalance0(e, e.msg.sender);

    swap(e, t, xIn, xOutMin);

    uint balanceOutAfter = is_t0 ? currentContract.getUserBalance1(e, e.msg.sender) : currentContract.getUserBalance0(e, e.msg.sender);
    
    mathint expectedMinBalanceOut = balanceOutBefore + xOutMin;
    assert(balanceOutAfter >= expectedMinBalanceOut);
}
