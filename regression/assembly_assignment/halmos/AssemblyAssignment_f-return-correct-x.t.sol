pragma solidity ^0.8.13;

import "target/AssemblyAssignment_v1.sol"; 

contract AssemblyAssignmentTest {
    AssemblyAssignment public target;

    //inizializazzione del contratto
    function setUp() public {
        target = new AssemblyAssignment();
    }

    function check_f_return_correct_x(uint x) public view {

        assert(target.f(x) == 2);
    }
}