function check_wd_onlyif_goal_reached(/*address payable user*/) public payable {
    
    require(block.number > end_donate);
    require(msg.value == 0);

    uint balanceBefore = address(this).balance;

    withdraw();
    // withdraw(user);

    assert(balanceBefore >= goal);

}