// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
 
import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund_v1.sol";
 
contract A {
    receive() external payable { revert(); }
}
 
contract CrowdfundTest is Test {
 
    Crowdfund public c;
    uint end_donate;
    uint goal;
 
    function setUp() public {
        
        // Deploy Crowdfund with a future deadline and a goal
        address payable owner = payable(address(this));
        end_donate = block.number + 10;
        goal = 100 ether;
        c = new Crowdfund(owner, end_donate, goal);
    }
 
    // reclaim-not-revert:
    // a transaction `reclaim` is not reverted if the goal amount is not reached
    // and the deposit phase has ended,
    // and the sender has donated funds that they have not reclaimed yet.
 
 
    // PoC produced by GPT-5:
    // - Deploy Crowdfund with end_donate in the future and goal = 100 ether.
    // - Deploy a contract A with receive() external payable { revert(); } (or a non-payable fallback).
    // - During the donation phase, A calls donate() with 1 ether.
    // - After end_donate has passed and total balance < goal (e.g., still 1 ether), A calls reclaim().
    // - All require checks in reclaim() pass, but the low-level call to A reverts,
    //  making succ = false and causing require(succ) to revert the transaction.
 
 
    function test_reclaim_not_revert() public {
        A _A = new A();
 
        // During donation phase: A calls donate() with 1 ether
        vm.roll(end_donate - 10);
 
        vm.deal(address(_A), 1 ether);
        vm.prank(address(_A));
        c.donate{value: 1 ether}();
 
        // After donation phase has passed: A calls reclaim()
        vm.roll(end_donate + 1);
        assert(address(c).balance < goal);
 
        // Check whether all require checks in reclaim() pass
        assert(block.number > end_donate);
        assert(address(c).balance < goal);
        assert(c.donation(address(_A)) > 0);
 
 
        // a transaction `reclaim` IS reverted even if the goal amount is not reached
        // and the deposit phase has ended,
        // and the sender has donated funds that they have not reclaimed yet.
        vm.expectRevert();
        vm.prank(address(_A));
        c.reclaim();
    }
 
}