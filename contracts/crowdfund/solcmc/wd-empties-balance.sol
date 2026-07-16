function check_wd_empties_balance(/*address payable user*/) public payable {
    
    require(block.number > end_donate);
    require(address(this).balance >= goal);
    require(msg.value == 0);
    
    withdraw();
    // withdraw(user);

    assert(address(this).balance == 0);
}