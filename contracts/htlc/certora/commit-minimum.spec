// SPDX-License-Identifier: GPL-3.0-only

// If `commit()` is successful, then `msg.value` is greater than or equal to `fee`

rule commit_minimum {
    env e;
    bytes32 b;

    commit(e, b);
    
    assert e.msg.value >= currentContract.fee;
}