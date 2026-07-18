// SPDX-License-Identifier: GPL-3.0-only

// No succesful function call should change contract's owner

rule owner_immutable(method f) {
    address _pre_owner = currentContract.owner;
    env e;
    calldataarg args;
    f(e, args);
    assert currentContract.owner == _pre_owner,
        "owner changed after calling function";
}