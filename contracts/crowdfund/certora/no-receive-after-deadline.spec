
/// no-receive-after-deadline:
/// the contract balance does not increase after
/// the end of the donation phase.

rule no_receive_after_deadline {
    env e;

    mathint bal_contract_prev = nativeBalances[currentContract];

    require(e.block.number > currentContract.end_donate);

    mathint bal_contract_next = nativeBalances[currentContract];

    assert bal_contract_next <= bal_contract_prev;
}