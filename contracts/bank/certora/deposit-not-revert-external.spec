// SPDX-License-Identifier: GPL-3.0-only

rule deposit_not_revert_external {
    env e;

    uint credits_sender = currentContract.credits[e.msg.sender];

    // this condition is needed to avoid trivial reverts due to insufficient balance
    require nativeBalances[e.msg.sender] >= e.msg.value; 

    // this condition is needed to avoid trivial reverts due to ETH overflow
    require credits_sender + e.msg.value <= max_uint;

    // external transaction
    require e.msg.sender == e.tx.origin;

    deposit@withrevert(e);
    
    assert !lastReverted;
}
