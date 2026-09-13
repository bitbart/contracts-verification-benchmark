// SPDX-License-Identifier: GPL-3.0-only

// In state `Reveal1` if contract balance is positive, some user can perform a non-reverting transaction that empties
// the contract balance

rule deadlock_freedom_reveal1 (method f)
filtered {
    f -> !f.isView && !f.isPure
} {
    env e;
    calldataarg args;

    require nativeBalances[currentContract] > 0;
    require status(e) == Lottery.Status.Reveal1;

    f(e, args);

    satisfy nativeBalances[currentContract] == 0;
}