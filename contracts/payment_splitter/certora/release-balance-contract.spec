import "helper/methods.spec";

rule release_balance_contract {
    env e;
    uint idx;
    address a = getPayee(idx);
    uint amt = releasable(a);

    require e.msg.value == 0;
    require idx < getPayeesLength();
    require a != currentContract;
    require getShares(a) > 0;
    require getTotalShares(e) > 0;
    require amt > 0;

    uint bal_before = nativeBalances[currentContract];

    release(e, a);

    uint bal_after = nativeBalances[currentContract];

    assert bal_before + amt == bal_after;
}
