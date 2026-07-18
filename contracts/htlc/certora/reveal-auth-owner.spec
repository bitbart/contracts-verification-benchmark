// SPDX-License-Identifier: GPL-3.0-only

// If `reveal()` is successfully called, then `msg.sender` must be the contract's owner

rule reveal_auth_owner {
    env e;
    string s;
    reveal(e, s);

    assert e.msg.sender == currentContract.owner;
}
