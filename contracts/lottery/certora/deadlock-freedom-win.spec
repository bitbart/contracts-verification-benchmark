// SPDX-License-Identifier: GPL-3.0-only

// In state `Win` if contract balance is positive, some user can perform a non-reverting transaction that empties
// the contract balance

rule deadlock_freedom_win (method f)
filtered {
    f -> !f.isView && !f.isPure
} {
    env e;
    calldataarg args;
    
    require nativeBalances[currentContract] > 0;
    require status(e) == Lottery.Status.Win;

    f(e, args);

    satisfy nativeBalances[currentContract] == 0;
}