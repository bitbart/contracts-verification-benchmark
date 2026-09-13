rule redeem_before_deadline_reverts_noreveal0 {
    env e;
    require currentContract.status == Lottery.Status.Reveal0;
    require e.block.number <= currentContract.end_reveal0;
    redeem1_noreveal0@withrevert(e);
    assert lastReverted;
}