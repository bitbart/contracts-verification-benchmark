// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import "target/{{VERSION}}.sol";
import "./BankHandler/bankHandler.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {Test} from "forge-std/Test.sol";

/// Property withdraw-sender-credit:
/// after a non-reverting `withdraw(amount)`, the credit of `msg.sender` is decreased by `amount`.
contract BankTest is Test, SymTest {
    Bank bank;
    BankHandler handler;

    function setUp() public {
        
        address owner = svm.createAddress("owner");
        vm.startPrank(owner);
        {{CONSTRUCTOR_SETUP}};
        vm.stopPrank();

        address user = svm.createAddress("A");
        handler = new BankHandler(address(bank), user);

        _assumeUser(owner);
        _assumeUser(user);
        excludeSender(address(0));
        excludeSender(address(bank));
        excludeSender(address(handler));
        excludeSender(address(this));

        // Halmos must explore only the Handler: direct calls to Bank
        // would skip the update of the ghost variables
        targetContract(address(handler));
    }

    function _assumeUser(address a) internal view {
        vm.assume(a != address(0));
        vm.assume(a != address(bank));
        vm.assume(a != address(handler));
        vm.assume(a != address(this));
    }

    /// @custom:halmos --invariant-depth 3
    function invariant_withdraw_sender_credit() public view {
        if (handler.lastSelector() == Bank.withdraw.selector) {
            assert(handler.senderCreditBefore() - handler.senderCreditAfter() == handler.lastAmount());
        }
    }
}
