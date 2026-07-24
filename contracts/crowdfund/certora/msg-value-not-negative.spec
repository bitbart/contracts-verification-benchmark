
/// msg-value-not-negative:
/// the `msg.value` for a call to `donate` should not be negative.

rule msg_value_not_negative {
    env e;
    
    donate@withrevert(e);

    assert e.msg.value >= 0;
}