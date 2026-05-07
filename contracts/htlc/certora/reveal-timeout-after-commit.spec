// SPDX-License-Identifier: GPL-3.0-only

rule reveal_timeout_after_commit {
    env e;
    calldataarg args;
    method f;

    f(e, args);

    assert (
        f.selector == sig:reveal(string).selector ||
        f.selector == sig:timeout().selector
    ) => currentContract.isCommitted;

}
