// SPDX-License-Identifier: GPL-3.0-only
rule cant_uncommit {
    env e;
    require currentContract.isCommitted, "after commit is set, it shouldn't be unset";

    method f;
    calldataarg args;

    f(e, args);

    assert currentContract.isCommitted;
}
