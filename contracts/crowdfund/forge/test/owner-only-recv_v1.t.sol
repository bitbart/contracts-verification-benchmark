// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
 
import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund_v1.sol";
 
contract CrowdfundTest is Test {
 
    Crowdfund public c;
    address payable owner;
    address payable constant O = payable(address(123));
    uint end_donate;
    uint goal;
 
    function setUp() public {
        
        // Deploy Crowdfund with a future deadline and a goal
        owner = O;
        end_donate = 100;
        goal = 10 ether;
        c = new Crowdfund(owner, end_donate, goal);
    }
 
    // owner-only-recv:
    // only the owner can receive ETH from the contract.
 
    // PoC produced by GPT-5:
    // - Deploy with owner = O, end_donate = 100, goal = 10 ether.
    // - At block 50, Alice donates 1 ether via donate().
    // - At block 101, balance (1 ether) < goal. Alice calls reclaim().
    // - The contract sends 1 ether to Alice (not the owner), violating the property.
 
 
    function test_owner_only_receive() public {
        address Alice = address(123);
 
        // At block 50
        vm.roll(50);
        vm.deal(Alice, 1 ether);
        vm.prank(Alice);
        c.donate{value: 1 ether}();
 
        // At block 101
        vm.roll(101);
        assert(address(c).balance < goal);
 
        uint Alice_balance_before = Alice.balance;        // Balance of Alice before reclaim()
 
        vm.prank(Alice);
        c.reclaim();
 
        uint Alice_balance_after = Alice.balance;        // Balance of Alice after reclaim()
 
        // Other donors (except the owner) CAN ALSO receive ETH from the contract.
        assert(Alice_balance_after > Alice_balance_before);
    }
 
}