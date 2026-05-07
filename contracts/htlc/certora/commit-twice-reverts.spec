// SPDX-License-Identifier: GPL-3.0-only

// actually multiple times calling commit -> use hooks

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
