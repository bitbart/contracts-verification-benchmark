/// @custom:property price-symmetry-strict
/// @custom:description The product of the prices of token0 and token1, as calculated by the `price` function, is always equal to 1e36.

rule price_symmetry_strict() {
    
    env e;
    
    // (t0 / t1) * (t1 / t0) * 1e18 * 1e18 = 1 * 1e36 = 1e36

    require(currentContract.t0(e) != currentContract.t1(e));
    require(currentContract.r0(e) > 0 && currentContract.r1(e) > 0);

    mathint p0 = currentContract.price(e, currentContract.t0(e));
    mathint p1 = currentContract.price(e, currentContract.t1(e));

    assert(p0 * p1 == 1000000000000000000000000000000000000);
}
