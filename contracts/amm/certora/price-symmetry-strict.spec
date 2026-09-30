/// @custom:property price-symmetry-strict
/// @custom:description Let `t0`, `t1` be the tokens held by the contract. The product between `price(t0)` and `price(t1)` is equal to 1e36.

rule price_symmetry_strict() {
    
    env e;
    
    mathint p0 = currentContract.price(e, currentContract.t0(e));
    mathint p1 = currentContract.price(e, currentContract.t1(e));

    assert(p0 * p1 == 1000000000000000000000000000000000000);
}
