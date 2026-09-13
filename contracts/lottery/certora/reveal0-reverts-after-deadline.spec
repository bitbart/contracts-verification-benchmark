/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery --verify Lottery:certora/reveal0-reverts-after-deadline.spec --optimistic_loop
rule reveal0_reverts_after_deadline {
    env e;
    string s;
    
    require e.block.number > currentContract.end_reveal0;
    reveal0@withrevert(e, s);
    assert lastReverted;
}