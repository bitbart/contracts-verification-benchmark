// SPDX-License-Identifier: GPL-3.0-only

rule reveal_auth_owner {
    env e;
    string s;
    reveal(e, s);

    assert e.msg.sender == currentContract.owner;
}
