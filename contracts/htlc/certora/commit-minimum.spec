// SPDX-License-Identifier: GPL-3.0-only

rule commit_minimum {
    env e;
    bytes32 b;

    commit(e, b);
    
    assert e.msg.value >= currentContract.fee, "fee is the minimum commit value";
}