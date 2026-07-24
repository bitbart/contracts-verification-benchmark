function check_msg_value_not_negative() public payable {

    donate();

    assert(msg.value >= 0);
}