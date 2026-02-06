// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v7.sol";


contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // deposit-assets-credit-others:
    // after a non-reverting deposit(), the credit of any user but the sender is preserved.

    // PoC produced by GPT-5:
    // Deploy the contract with owner = O.
    // Let A ≠ O call deposit() with msg.value = 1 wei.
    // The call does not revert.
    // Before: credits[O] = 0.
    // After: credits[O] = 1 (increased), even though O ≠ A.
    // Thus, a non-sender’s credit was not preserved.


    function test_deposit_assets_credit_others(address A) public {
        // Initialization
        address owner = address(123);
        vm.assume(A != owner);

        // Owner deploys the Bank contract
        vm.prank(owner);
        b = new Bank();

        // Funding A
        vm.deal(address(A), 1 ether);

        bytes32 slot_1 = keccak256(abi.encode(address(owner), uint256(0)));
        uint owner_credits_before = uint256(vm.load(address(b), slot_1));
        
        // A deposits 1 wei
        vm.prank(address(A));
        b.deposit{value: 1}();
        
        bytes32 slot_2 = keccak256(abi.encode(address(owner), uint256(0)));
        uint owner_credits_after = uint256(vm.load(address(b), slot_2));

        
        // Owner's credit increases even though it did not call deposit
        // After a non-reverting deposit(), the credit of a user (here, owner) but the sender is NOT preserved
        assert(owner_credits_before != owner_credits_after);
    }

}