rule redeem_before_deadline_reverts_nojoin1 {
    env e;
    require currentContract.status == Lottery.Status.Join1;
    require e.block.number <= currentContract.end_join;
    redeem0_nojoin1@withrevert(e);
    assert lastReverted;
}