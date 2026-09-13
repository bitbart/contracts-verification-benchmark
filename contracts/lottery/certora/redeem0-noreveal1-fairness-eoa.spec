// SPDX-License-Identifier: GPL-3.0-only

// Assuming `player0` and `player1` behave as EOAs: if the contract is in `Reveal1` status and evaluating the fair
// function would result in `player0` being the winner; then a `redeem0_noreveal1` non-reverting transaction strictly
// increases `player0`'s ETH balance, leaves `player1`'s ETH balance unchanged, and strictly decreases the contract's
// ETH balance.

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery versions/lib/EOA0.sol versions/lib/EOA1.sol --verify Lottery:certora/redeem0-noreveal1-fairness-eoa.spec --link Lottery:player0=EOA0 --link Lottery:player1=EOA1 --optimistic_hashing --optimistic_loop
rule redeem0_noreveal1_fairness_eoa {
    env e;
    require _status(e) == 3;
    require e.block.number > currentContract.end_reveal1;

    address _p0;
    require _p0 == currentContract.player0;
    require _p0 != currentContract;

    address _p1;
    require _p1 == currentContract.player1;
    require _p1 != currentContract;

    require _p0 != _p1;

    string _s0;
    require _s0 == secret0(e);

    string _s1;
    require hashing(e, _s1) == currentContract.hash1;

    require compute_winner(e, _p0, _p1, _s0, _s1) == _p0;

    mathint bet = currentContract.bet_amount;
    require bet >= MINIMUM_BET(e);

    mathint p0_pre_bal = nativeBalances[_p0];
    mathint p1_pre_bal = nativeBalances[_p1];
    mathint contract_pre_bal = nativeBalances[currentContract];
    require contract_pre_bal == bet * 2;

    redeem0_noreveal1(e);

    mathint p0_post_bal = nativeBalances[_p0];
    mathint p1_post_bal = nativeBalances[_p1];
    mathint contract_post_bal = nativeBalances[currentContract];

    assert p0_post_bal > p0_pre_bal;
    assert p1_post_bal == p1_pre_bal;
    assert contract_post_bal < contract_pre_bal;
}
