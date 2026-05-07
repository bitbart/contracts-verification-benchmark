// SPDX-License-Identifier: GPL-3.0-only

ghost mathint commit_called {
    init_state axiom commit_called == 0;
}

hook CALL(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
    if (selector == sig:commit(bytes32).selector) {
        commit_called = commit_called + 1; 
    }
}

invariant multiple_commits()
    commit_called <= 1;