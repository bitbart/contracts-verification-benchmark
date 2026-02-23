/// no-donate-after-deadline:
/// calls to `donate` will revert if
/// the donation phase has ended.

rule no_donate_after_deadline {
    env e;
    
    require(e.block.number > currentContract.end_donate);

    donate@withrevert(e);    
    assert lastReverted;
}


