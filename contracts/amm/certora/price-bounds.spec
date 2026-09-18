/// @custom:property price-bounds
/// @custom:description If the reserve of token0 is greater than the reserve of token1, the `price` function returns a value for token1 that is greater than the value for token0.

rule price_bounds() {

    env e;
    
    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.r1(e) > 0 && currentContract.r0(e) > currentContract.r1(e));

    mathint p0 = currentContract.price(e, currentContract.t0(e));
    mathint p1 = currentContract.price(e, currentContract.t1(e));

    assert(p1 > p0);
}
