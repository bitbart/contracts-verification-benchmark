// the reserves are strictly positive if a deposit has been made

rule reserves_gt_zero {
    assert currentContract.ever_deposited => currentContract.r0>0 && currentContract.r1>0;
}
