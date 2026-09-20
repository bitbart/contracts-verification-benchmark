/// @custom:property price-equality
/// @custom:description Let `r0`, `r1` be the tracked internal reserves of the contract, and let `t0`, `t1` be the tokens held by the contract. If `r0 > 0` and `r0 == r1`, then `price(t0)` == `price(t1)`.

rule price_equality() {

    env e;

    require(currentContract.r0(e) == currentContract.r1(e) && currentContract.r0(e) > 0);

    mathint p0 = currentContract.price(e, currentContract.t0(e));
    mathint p1 = currentContract.price(e, currentContract.t1(e));

    assert(p0 == p1);
}
