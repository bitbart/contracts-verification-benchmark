// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
 
import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund_v1.sol";
 
contract CrowdfundTest is Test {
 
    Crowdfund public c;
    uint end_donate;
    uint goal;
 
    function setUp() public {
        
        // Deploy Crowdfund
        address payable owner = payable(address(123));
        end_donate = block.number + 10;
        goal = 1 ether;
        c = new Crowdfund(owner, end_donate, goal);
    }
 
    // reclaim-even-if-msgvalue:
    // For a call to `reclaim` by `msg.sender` A,
    // the call executes as expected even if `msg.value` is non-zero.
 
    // PoC produced by GPT-5:
    // - Setup: end_donate has passed, address(this).balance < goal,
    //  and Alice (A) has donation[A] > 0 (e.g., A donated before end_donate).
    // - Action: Alice calls reclaim() sending 1 wei (msg.value = 1).
    // - Result: The call reverts immediately because reclaim is non-payable, so it does not execute as expected.
 
    function test_reclaim_even_if_msgvalue() public {
        address Alice = address(456);
 
        // Before end_donate:
        vm.roll(end_donate - 1);
 
        vm.deal(Alice, 1 ether);
        vm.prank(Alice);
        c.donate{value: 2 wei}();
 
        // After end_donate:
        vm.roll(end_donate + 1);
        assert(address(c).balance < goal);
        assert(c.donation(Alice) > 0);
 
        // For a call to `reclaim` by `msg.sender` A,
        // the call REVERTS when `msg.value` is non-zero.
        vm.prank(Alice);
        (bool success,) = address(c).call{value: 1 wei}(abi.encodeWithSignature("reclaim()"));
        assert(!success);
    }
 
}