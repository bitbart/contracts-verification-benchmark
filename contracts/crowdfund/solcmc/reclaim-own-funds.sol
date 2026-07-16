function check_reclaim_own_funds() public payable {
    require(block.number > end_donate);
    require(address(this).balance < goal);
    
    require(msg.sender != address(0));
    require(msg.sender != address(this));
    require(donation[msg.sender] > 0);
    
    require(address(this).balance >= donation[msg.sender]);

    uint donorBalanceBefore = msg.sender.balance;
    uint expectedRefund = donation[msg.sender];

    require(msg.value == 0);

    reclaim();

    uint donorBalanceAfter = msg.sender.balance;

    assert(donorBalanceAfter == donorBalanceBefore + expectedRefund);
}