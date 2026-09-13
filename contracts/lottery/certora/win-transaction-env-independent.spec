// SPDX-License-Identifier: GPL-3.0-only

// Two non-reverting `win` transactions performed from equal contract state yield the same result

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery --verify Lottery:certora/win-transaction-env-independent.spec --optimistic_loop --optimistic_hashing

rule win_transaction_env_independent {
    env e1;
    env e2;

    require currentContract.status == Lottery.Status.Win;

    storage initState = lastStorage;

    win(e1);
    address winner1 = currentContract.winner;

    win(e2) at initState;
    address winner2 = currentContract.winner;

    assert winner1 == winner2 && nativeBalances[winner1] == nativeBalances[winner2];
}
