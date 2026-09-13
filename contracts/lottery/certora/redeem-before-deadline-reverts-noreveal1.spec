rule redeem_before_deadline_reverts_noreveal1 {
    env e;
    require currentContract.status == Lottery.Status.Reveal1;
    require e.block.number <= currentContract.end_reveal1;
    redeem0_noreveal1@withrevert(e);
    assert lastReverted;
}