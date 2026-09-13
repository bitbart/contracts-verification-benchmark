// SPDX-License-Identifier: GPL-3.0-only

// Assuming `player0` and `player1` are EOAs: if the honest protocol would result in `expected_winner` to be the
// winner of the lottery, a non-reverting `win` transaction must increase `expected_winner` ETH balance by the pot

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery versions/lib/EOA0.sol versions/lib/EOA1.sol --verify Lottery:certora/win-pays-fair-winner-eoa.spec --link Lottery:player0=EOA0 --link Lottery:player1=EOA1 --optimistic_hashing --optimistic_loop
rule win_pays_fair_winner_eoa {
    env e;
    require currentContract.status == Lottery.Status.Win;

    address p0 = currentContract.player0;
    address p1 = currentContract.player1;
    require p0 != currentContract;
    require p1 != currentContract;
    require p0 != p1;

    address expected_winner = compute_winner(e, p0, p1, secret0(e), secret1(e));
    mathint pre_bal = nativeBalances[expected_winner];
    mathint pre_pot = nativeBalances[currentContract];

    win(e);

    assert (
        nativeBalances[expected_winner] == pre_bal + pre_pot &&
        nativeBalances[currentContract] == 0
    );
}
