/// @custom:property price-equality
/// @custom:description If the tracked reserves of the contract are equal and positive, the `price` function returns identical values for both token0 and token1.

rule price_equality() {

    env e;

    require(currentContract.r0(e) == currentContract.r1(e) && currentContract.r0(e) > 0);

    uint price0 = currentContract.price(e, currentContract.t0(e));
    uint price1 = currentContract.price(e, currentContract.t1(e));

    assert(price0 == price1);
}
