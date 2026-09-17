// SPDX-License-Identifier: GPL-3.0-only

// After a non-reverting `reveal0` transaction, assuming `player0` and
// `player1` are EOAs, some user can perform, either immediately, or in the
// future provided there are no in-between transactions, a `redeem0_noreveal1` 
// transaction that makes `player0` redeem the pot

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery versions/lib/EOA0.sol versions/lib/EOA1.sol --verify Lottery:certora/no-incentives-to-abort-witness-eoa.spec --link Lottery:player0=EOA0 --link Lottery:player1=EOA1 --optimistic_hashing --optimistic_loop

/// @custom:negate
rule no_incentives_to_abort_eoa_witness {
    env e_reveal0;
    calldataarg args_reveal0;

    env e_redeem;
    calldataarg args_redeem;

    address p0 = currentContract.player0;
    address p1 = currentContract.player1;
    require p0 != p1;

    reveal0(e_reveal0, args_reveal0);
    
    mathint pre_p0_bal = nativeBalances[p0];
    mathint pre_p1_bal = nativeBalances[p1];
    mathint pre_contract_bal = nativeBalances[currentContract];

    require pre_contract_bal > 0;
    require currentContract.status == Lottery.Status.Reveal1;
    
    redeem0_noreveal1(e_redeem, args_redeem);
        
    mathint post_p0_bal = nativeBalances[p0];
    mathint post_p1_bal = nativeBalances[p1];
    mathint post_contract_bal = nativeBalances[currentContract];

    assert (
        post_p0_bal != pre_p0_bal + pre_contract_bal ||
        post_contract_bal != 0 ||
        post_p1_bal != pre_p1_bal ||
        currentContract.status != Lottery.Status.End
    );
}