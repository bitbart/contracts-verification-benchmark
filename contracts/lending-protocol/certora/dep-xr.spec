// SPDX-License-Identifier: GPL-3.0-only

// import "erc20.spec";

rule xr_compute(address t) {
    env e;

    require(currentContract.isValidToken(e, t));
    
    uint actual_xr = currentContract.XR(e, t);

    uint r_t = currentContract.reserves[t];
    uint c_t = currentContract.sum_credits[t];
    uint d_t = currentContract.getUpdatedSumDebits(e, t);

    require (r_t + c_t < max_uint);

    // require(actual_xr == currentContract.XR_def(e, c_t, d_t, r_t));

    mathint computed_xr;
    if (c_t == 0) { 
        computed_xr = 1000000;
    }
    else {
        computed_xr = ((r_t + d_t) * 1000000) / c_t;
    }

    assert (computed_xr == actual_xr);
}

rule dep_xr {
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
    uint old_reserves_t1 = currentContract.reserves[t1];
    uint old_credit_t0_a = currentContract.credit[t0][a];
    uint old_credit_t1_a = currentContract.credit[t1][a];
    uint old_credit_t0_b = currentContract.credit[t0][b];
    uint old_credit_t1_b = currentContract.credit[t1][b];
    uint old_xr_t0 = currentContract.XR(e, t0);

    uint old_sum_credits_t0 = currentContract.sum_credits[t0];
    uint old_sum_debits_t0 = currentContract.getUpdatedSumDebits(e, t0);

    require(old_sum_credits_t0 > 0);

    mathint old_computed_xr_t0; 

    if (old_sum_credits_t0 == 0) {
        old_computed_xr_t0 = 1000000;
    }
    else {
        old_computed_xr_t0 = ((old_reserves_t0 + old_sum_debits_t0) * 1000000) / old_sum_credits_t0;
    }

    //require(old_xr_t0 >= 1000000); //requirement is not necessary relative to skeleton

    deposit(e, amt, t0);

    uint new_reserves_t0 = currentContract.reserves[t0];   
    uint new_reserves_t1 = currentContract.reserves[t1];
    uint new_credit_t0_a = currentContract.credit[t0][a];
    uint new_credit_t1_a = currentContract.credit[t1][a];
    uint new_credit_t0_b = currentContract.credit[t0][b];
    uint new_credit_t1_b = currentContract.credit[t1][b];
    uint new_xr_t0 = currentContract.XR(e, t0);

    uint new_sum_credits_t0 = currentContract.sum_credits[t0];
    uint new_sum_debits_t0 = currentContract.getUpdatedSumDebits(e, t0);

    mathint new_computed_xr_t0; 
    
    if (new_sum_credits_t0 == 0) {
        new_computed_xr_t0 = 1000000;
    }
    else {
        new_computed_xr_t0 = ((new_reserves_t0 + new_sum_debits_t0) * 1000000) / new_sum_credits_t0;
    }

    assert(new_reserves_t0 == old_reserves_t0 + amt);
    assert(new_reserves_t1 == old_reserves_t1);

    assert(new_credit_t0_a == old_credit_t0_a + (amt * 1000000) / old_xr_t0);
    assert(new_credit_t1_a == old_credit_t1_a);

    assert(new_credit_t0_b == old_credit_t0_b);
    assert(new_credit_t1_b == old_credit_t1_b);

    assert(old_xr_t0 == old_computed_xr_t0);
    assert(new_xr_t0 == new_computed_xr_t0);

    // assert(new_xr_t0 >= 1000000);

    assert(new_sum_credits_t0 == old_sum_credits_t0 + ((amt * 1000000)/old_computed_xr_t0));
    assert(new_sum_debits_t0 == old_sum_debits_t0);

    // assert(old_computed_xr_t0 == new_computed_xr_t0); //requirement is not necessary relative to skeleton
    
    // false because of roundings (integer arithmetics)
    assert(old_xr_t0 <= new_xr_t0);
    assert(new_xr_t0 <= old_xr_t0 + ((amt * 1000000)/old_sum_credits_t0) + 1);
}