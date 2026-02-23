// owner-only-recv:
// only the owner can receive ETH from the contract.

hook CALL(uint g, address addr, uint value, uint argsOffset, uint argsLength, uint retOffset, uint retLength) uint rc {
    assert (addr != currentContract.owner => value == 0);
}

rule owner_only_recv {
    env e;
    method f;
    calldataarg args;
    
    f(e, args);
}