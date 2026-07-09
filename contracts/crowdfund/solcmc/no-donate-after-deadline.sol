function check_no_donate_after_deadline() public payable {
    require(block.number > end_donate);

    donate();

    assert(false);
}