// SPDX-License-Identifier: GPL-3.0-only

// If a `join1` transaction doesn't revert then `msg.value` matched the bet from `player0`

rule player1_should_match_bet {
    env e;
    bytes32 h;
    require currentContract.status == Lottery.Status.Join1;

    join1(e, h);

    assert e.msg.value == currentContract.bet_amount;
}
