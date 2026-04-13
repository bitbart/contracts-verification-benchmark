// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
 
import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund_v1.sol";
 
contract CrowdfundTest is Test {
 
    Crowdfund public c;
 
    function setUp() public {
        
        // Deploy Crowdfund with a future deadline and a goal
        address payable owner = payable(address(this));
        uint end_donate = block.number + 10;
        uint goal = 10 ether;
        c = new Crowdfund(owner, end_donate, goal);
    }
 
    // exists-unique-donation-change:
    // after a non-reverting `donate` transaction to the Crowdfund contract,
    // the donation of exactly one user has changed.
 
    // PoC produced by GPT-5:
    // - Deploy the contract with end_donate set to a future block (e.g., current block + 10), any owner, any goal.
    // - A user calls donate() with msg.value = 0 while block.number <= end_donate.
    // - The call does not revert, but donation[user] remains unchanged, so the donation of zero users has changed.
 
 
    function test_exists_unique_donation_change() public {
        // Initialization
        address user = address(456);
 
        // Funding user with 1 ETH
        vm.deal(user, 1 ether);
 
        uint user_donation_before = c.donation(user);        // donation[user] before donate()
 
        // user calls donate() with msg.value = 0
        vm.prank(user);
        (bool success,) = address(c).call{value: 0 ether}(abi.encodeWithSignature("donate()"));
        assert(success);                                    // Ensuring donate() does not revert
 
        uint user_donation_after = c.donation(user);        // donation[user] after donate()
 
 
        // after a non-reverting `donate` transaction to the Crowdfund contract,
        // the donation of exactly one user has NOT changed.
        assert(user_donation_before == user_donation_after);
    }
 
}