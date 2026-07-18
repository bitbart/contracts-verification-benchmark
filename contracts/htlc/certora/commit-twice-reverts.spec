// SPDX-License-Identifier: GPL-3.0-only

// After a succesful `commit()` call, any immediate following calls to `commit()` must revert

rule commit_twice_reverts {
    env e;
    bytes32 b;
    commit(e, b);

    method f;
    calldataarg args;
    f@withrevert(e, args);

    assert
        (f.selector == sig:commit(bytes32).selector)
        => lastReverted,
        "commit cannot be called two times in a row";
}
