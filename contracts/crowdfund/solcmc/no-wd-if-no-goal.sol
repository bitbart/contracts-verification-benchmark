function check_no_wd_if_no_goal(/*address payable _user*/) public payable {
    require(address(this).balance < goal);
    require(msg.value == 0);

    withdraw();
    // withdraw(_user);

    assert(false);
}
