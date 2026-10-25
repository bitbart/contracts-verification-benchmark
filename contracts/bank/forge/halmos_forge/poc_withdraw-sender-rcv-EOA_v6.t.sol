// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import {Test} from "forge-std/Test.sol";
import {Bank} from "versions/Bank_v6.sol";

// sender_is_contract = 0 in every tx => sender is the EOA halmos_msg_sender = 0x8000...0000
// tx.origin = 0x8000000000000000000000000000000000000000 (= msg.sender: the tx is originated by an EOA)
// tx1: deposit()                                    p_value  = 0x100000000000000000000000000000000
// tx2: withdraw(0x7fffffffffffffffffffffffffffffff)  
// The bug: withdraw sends amount + 1 wei to msg.sender
contract PoC_WithdrawSenderRcvEOA_v6 is Test {

    address constant SENDER = 0x8000000000000000000000000000000000000000;

    Bank bank;

    function setUp() public {
        bank = new Bank();
    }

    function test_poc_withdraw_sender_rcv_EOA() public {
        uint256 value = 0x100000000000000000000000000000000;
        vm.deal(SENDER, value);
        vm.prank(SENDER, SENDER);
        bank.deposit{value: value}();

        // tx2: the EOA withdraws `amount`
        uint256 amount = 0x7fffffffffffffffffffffffffffffff;
        uint256 balanceBefore = SENDER.balance;

        vm.prank(SENDER, SENDER);
        bank.withdraw(amount);

        uint256 balanceAfter = SENDER.balance;

        // property: after a non-reverting withdraw(amount) originated by an EOA,
        // the balance of msg.sender is increased by amount
        // on v6 this is violated: the balance is increased by amount + 1
        assertNotEq(balanceAfter - balanceBefore, amount, "withdraw-sender-rcv-EOA holds: counterexample not reproduced");
    }
}
