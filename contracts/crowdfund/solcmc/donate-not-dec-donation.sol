function check_donate_not_dec_donation() public payable {
    require(block.number <= end_donate);

    uint donorBefore = donation[msg.sender];

    donate(); 

    assert(donation[msg.sender] >= donorBefore);
}