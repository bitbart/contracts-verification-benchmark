// SPDX-License-Identifier: GPL-3.0-only

// import "erc20.spec";


rule rdm_xr_eq {
    env e;
    address t0;
    address t1;
    address a;
    address b;
    uint amt;

    require(a != b && a!=0 && b!=0 && a!=currentContract && b!=currentContract);
    require(t0 != t1);

    require (e.msg.sender == a);
    require (currentContract.isValidToken(e, t0));



    uint old_reserves_t0 = currentContract.reserves[t0];   
    uint old_xr_t0 = currentContract.XR(e, t0);

    uint old_sum_credits_t0 = currentContract.sum_credits[t0];
    uint old_sum_debits_t0 = currentContract.getUpdatedSumDebits(e, t0);

    redeem(e, amt, t0);

    uint new_reserves_t0 = currentContract.reserves[t0];   
    uint new_xr_t0 = currentContract.XR(e, t0);

    uint new_sum_credits_t0 = currentContract.sum_credits[t0];
    uint new_sum_debits_t0 = currentContract.getUpdatedSumDebits(e, t0);

    // XR can increase in some cases, we expect the prover to return false
    assert(old_xr_t0 == new_xr_t0);
}