/// @custom:property reserves-not-drained
/// @custom:description If `r0 > 0` and `r1 > 0`, then after any non-reverting transaction to the contract, `r0 > 0` and `r1 > 0`.

rule reserves_not_drained {
    env e;
    method f;
    calldataarg args;

    require(currentContract.r0(e) > 0 && currentContract.r1(e) > 0);

    f(e, args);

    assert(currentContract.r0(e) > 0 && currentContract.r1(e) > 0);
}
