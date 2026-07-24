function invariant(uint choice/*, address payable _newOwner, uint amount, address payable user*/) public payable {
    
    require(block.number > end_donate);

    uint _balance = address(this).balance;

    if (choice == 0) {
        donate();
    } else if (choice == 1) {
        withdraw();
        // withdraw(user);
    } else if (choice == 2) {
        reclaim();
    // } else if (choice == 3) {
    //     setOwner(_newOwner);
    // } else if (choice == 3) {
    //     require(msg.sender == owner); 
    //     setGoal(amount);
    // } else if (choice == 3) {
    //     clawback();
    } else {
        require(false);
    }
    
    require(address(this).balance < _balance);
    assert(choice == 1 || choice == 2);
}