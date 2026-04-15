// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v4.sol";


contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // deposit-assets-credit:
    // after a non-reverting deposit(), the credits of msg.sender are increased by msg.value.

    // PoC produced by GPT-5:
    // Let a user with initial credits 0 call deposit() with msg.value = 1 wei.
    // The call does not revert, but credits increase by 0 (1 - 1), not by 1, violating the property.


    function test_deposit_assets_credit() public {
        // Initialization
        address owner = address(123);
        address user = address(456);

        // Owner deploys the Bank contract
        vm.prank(owner);
        b = new Bank();

        // Funding user
        vm.deal(address(user), 1 ether);
        
        // User deposits 1 wei
        vm.prank(address(user));

        bytes32 slot1 = keccak256(abi.encode(address(user), uint256(0)));
        uint user_credits_before = uint256(vm.load(address(b), slot1));

        uint deposit_value = 1;
        (bool success,) = address(b).call{value: deposit_value}(abi.encodeWithSignature("deposit()"));
        assert(success);                                       // Ensuring deposit() does not revert
        
        bytes32 slot2 = keccak256(abi.encode(address(user), uint256(0)));
        uint user_credits_after = uint256(vm.load(address(b), slot2));

        // After a non-reverting deposit(), the credits of msg.sender are NOT increased by msg.value
        assert(user_credits_before != user_credits_after + deposit_value);
    }

}