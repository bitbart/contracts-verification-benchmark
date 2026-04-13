
/// wd-transfer-to-owner:
// after a non-reverting `withdraw`, the ETH balance of owner is increased by an amount
// equal to the balance (of Crowdfund) before `withdraw` was called.

rule wd_transfer_to_owner {
    env e;
    
    require(nativeBalances[currentContract] >= currentContract.goal);
    require(e.block.number > currentContract.end_donate);
    require(e.msg.value == 0);

    mathint contract_old_balance = nativeBalances[currentContract];
    mathint owner_old_balance = nativeBalances[currentContract.owner];

    withdraw@withrevert(e);

    mathint owner_new_balance = nativeBalances[currentContract.owner];

    assert !lastReverted =>
    owner_new_balance == owner_old_balance + contract_old_balance;
}