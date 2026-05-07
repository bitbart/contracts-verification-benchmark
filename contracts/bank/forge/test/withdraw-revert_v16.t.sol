// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v16.sol";

contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // withdraw-revert:
    // a withdraw(amount) call reverts if amount is zero or greater than the credit of msg.sender.

    // PoC produced by GPT-5:
    // - Fresh deployment; credits[A] == 0 for any user A.
    // - A calls withdraw(1).
    // - require(amount > 0) passes;
    // unchecked subtraction underflows credits[A];
    // the call attempts to send 1 wei and returns a boolean.
    // The transaction does not revert, violating the property.




    function test_withdraw_revert(address A) public {
        // owner deploys the Bank contract
        address owner = address(123);
        vm.prank(owner);
        b = new Bank();

        bytes32 slot = keccak256(abi.encode(A, uint256(0)));
        uint A_credits = uint256(vm.load(address(b), slot));            // Credits of A at the beginning
        assert(A_credits == 0);


        // A calls withdraw
        // The withdraw(amount) call DOES NOT revert even when the amount is greater than the credit of msg.sender (here, A)
        vm.prank(A);
        (bool success,) = address(b).call(abi.encodeWithSignature("withdraw(uint256)", 1));       // Ensuring withdraw() succeeds
        assert(success);                                                        

    }

}