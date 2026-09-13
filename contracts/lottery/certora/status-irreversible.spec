// SPDX-License-Identifier: GPL-3.0-only

// If a user performs a non-reverting transaction then the contract's state after the transaction is strictly
// greater than it was before

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery --verify Lottery:certora/status-irreversible.spec --optimistic_hashing --optimistic_loop
rule status_irreversible(method f)
filtered {
    f -> !f.isView && !f.isPure && f.contract == currentContract
} {
    env e;
    calldataarg args;

    mathint pre_status = to_mathint(currentContract.status);

    f(e, args);

    mathint post_status = to_mathint(currentContract.status);

    assert post_status > pre_status;
}
