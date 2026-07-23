// SPDX-License-Identifier: GPL-3.0-only

// If `commit()` is successful, then isCommitted was false before the call
rule commit_not_revert{
    env e;
    calldataarg args;

    bool pre_isCommitted = currentContract.isCommitted;

    commit@withrevert(e, args);

    assert !lastReverted => (!pre_isCommitted);
}