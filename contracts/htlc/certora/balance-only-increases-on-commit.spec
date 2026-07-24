// SPDX-License-Identifier: GPL-3.0-only

// The contract's balance should only increase if the `commit()` function is called

rule balance_only_increases_on_commit {
    env e;
    method f;
    calldataarg args;
    mathint pre_bal = nativeBalances[currentContract];
    require e.msg.value > 0;
    f(e, args);

    mathint post_bal = nativeBalances[currentContract];
    assert (post_bal > pre_bal) => (
        f.selector == sig:commit(bytes32).selector
    );
}