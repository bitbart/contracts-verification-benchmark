// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v5.sol";


contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // deposit-additivity:
    // two non-reverting consecutive (i.e., not interleaved with other transactions) deposit of n1 and n2 wei
    // performed by the same sender are equivalent to a single deposit of n1+n2 wei of T.
    
    // PoC produced by GPT-5:
    // Let credits[A] = 0 initially.
        // - Two deposits by A: first with n1 = 1 wei (credits += 2), then n2 = 2 wei (credits += 3). Final credits[A] = 5.
        // - Single deposit by A of n1 + n2 = 3 wei (credits += 4). Final credits[A] = 4.\nSince 5 ≠ 4, the two sequences are not equivalent.


    function test_deposit_additivity(address owner) public {
        // Initialization
        address A = address(456);

        // Owner deploys the Bank contract
        vm.prank(owner);
        b = new Bank();

        // Funding A
        vm.deal(address(A), 1 ether);

        // Scenario 1: A deposits 1 wei & 2 wei consecutively
        uint256 snapshot = vm.snapshot();
        vm.startPrank(address(A));
        b.deposit{value: 1}();
        b.deposit{value: 2}();
        vm.stopPrank();

        bytes32 slot_1 = keccak256(abi.encode(address(A), uint256(0)));
        uint A_credits_scenario1 = uint256(vm.load(address(b), slot_1));

        
        // Scenario 2: A deposits 3 wei at once
        vm.revertTo(snapshot);
        vm.prank(address(A));
        b.deposit{value: 3}();
        
        bytes32 slot_2 = keccak256(abi.encode(address(A), uint256(0)));
        uint A_credits_scenario2 = uint256(vm.load(address(b), slot_2));


        // Two non-reverting consecutive deposits of 1 & 2 wei
        // performed by the same sender A are not equivalent to a single deposit of 3 wei
        assertNotEq(A_credits_scenario1, A_credits_scenario2);
    }

}