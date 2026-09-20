/// @custom:property deposit-precision
/// @custom:description After a non-reverting deposit(x0, x1) transaction where `x0 >= r0/1000` and `x1 >= r1/1000`, the minted liquidity tokens (`minted`) satisfy `minted > 0`, `minted / supplyBefore <= x0 / r0`, and `minted / supplyBefore <= x1 / r1`, where `r0`, `r1`, and `supplyBefore` denote the state before the deposit.

rule deposit_precision {

    env e;
    uint x0;
    uint x1;
    uint r0 = currentContract.r0(e);
    uint r1 = currentContract.r1(e);
    uint supplyBefore = currentContract.supply(e);


    require(currentContract.t0(e) != currentContract.t1(e));
    require(e.msg.sender != currentContract);


    require(x0 * 1000 >= r0);
    require(x1 * 1000 >= r1);


    deposit(e, x0, x1);


    uint supplyAfter = currentContract.supply(e);
    mathint minted = supplyAfter - supplyBefore;


    assert(minted > 0);
    assert(minted * r0 <= x0 * supplyBefore);
    assert(minted * r1 <= x1 * supplyBefore);
}