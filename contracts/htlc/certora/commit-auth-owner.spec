// SPDX-License-Identifier: GPL-3.0-only

// If `commit()` is successful, then `msg.sender` must be the contract's owner

rule commit_auth_owner {
    env e;
    bytes32 b;
    commit(e, b);
    
    assert e.msg.sender == currentContract.owner;
}
