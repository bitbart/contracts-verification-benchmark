// SPDX-License-Identifier: GPL-3.0-only
// The overall sent amount does not exceed the initial deposit.

ghost mathint total_sent {
    init_state axiom total_sent == 0;
}

ghost mathint _deposited {
    init_state axiom _deposited == 0;
}

hook CALL(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
    total_sent = total_sent + value;
}

hook Sstore isCommitted bool newVal (bool oldVal) {
    if (newVal && !oldVal) {
        _deposited = to_mathint(nativeBalances[currentContract]);
    }
}

invariant inv()
    total_sent <= _deposited;
