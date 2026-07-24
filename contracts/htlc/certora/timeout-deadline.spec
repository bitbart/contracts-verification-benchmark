// SPDX-License-Identifier: GPL-3.0-only

// If `timeout()` is successful, the transaction must have occurred at a block number greater than or equal to the contract's initial block plus `waitTime`

rule timeout_deadline {
    env e;
    
    timeout(e);
    
    assert to_mathint(e.block.number) >= currentContract.start + currentContract.waitTime;
}
