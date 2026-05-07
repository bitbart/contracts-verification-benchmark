// SPDX-License-Identifier: GPL-3.0-only

rule timeout_deadline {
    env e;
    
    timeout(e);
    
    assert to_mathint(e.block.number) >= currentContract.start + currentContract.waitTime;
}
