/// @custom:property price-bounds
/// @custom:description Let `r0`, `r1`, be respectevely the reserves of `t0` and `t1` held by the contract. If `r0 > r1`, then `price(t1)` > `price(t0)`.

rule price_bounds() {

    env e;
    
    require(currentContract.r1(e) > 0 && currentContract.r0(e) > currentContract.r1(e));

    mathint p0 = currentContract.price(e, currentContract.t0(e));
    mathint p1 = currentContract.price(e, currentContract.t1(e));

    assert(p1 > p0);
}
