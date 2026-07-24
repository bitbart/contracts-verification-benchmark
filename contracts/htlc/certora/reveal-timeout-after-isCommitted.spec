// SPDX-License-Identifier: GPL-3.0-only

// `reveal()` and `timeout()` can only be successfully called if contract is in a committed state

rule reveal_timeout_after_isCommitted {
    env e;
    calldataarg args;
    method f;

    f(e, args);

    assert (
        f.selector == sig:reveal(string).selector ||
        f.selector == sig:timeout().selector
    ) => currentContract.isCommitted;

}
