// SPDX-License-Identifier: GPL-3.0-only

rule commit_auth_owner {
    env e;
    bytes32 b;
    commit(e, b);
    
    assert e.msg.sender == currentContract.owner;
}
