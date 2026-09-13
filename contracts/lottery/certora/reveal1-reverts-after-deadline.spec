/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery --verify Lottery:certora/reveal1-reverts-after-deadline.spec --optimistic_loop
rule reveal1_reverts_after_deadline {
    env e;
    string s;
    require e.block.number > currentContract.end_reveal1;
    reveal1@withrevert(e, s);
    assert lastReverted;
}