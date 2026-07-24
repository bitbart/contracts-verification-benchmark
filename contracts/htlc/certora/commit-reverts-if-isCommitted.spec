// SPDX-License-Identifier: GPL-3.0-only

// If contract is already in a committed state, then any following `commit()` calls must revert

rule commit_reverts_if_isCommitted {
    env e;

    require currentContract.isCommitted;

    bytes32 hash;
    commit@withrevert(e, hash);

    assert lastReverted;
}
