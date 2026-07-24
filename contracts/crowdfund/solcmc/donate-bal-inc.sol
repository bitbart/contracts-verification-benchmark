function check_donate_bal_inc() public payable {
    
    require(block.number <= end_donate);

    uint oldBalance = address(this).balance;

    donate();
    // if the call reverts the rule passes

    assert(oldBalance <= address(this).balance);

}