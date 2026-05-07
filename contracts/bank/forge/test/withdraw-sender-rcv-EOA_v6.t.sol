// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v6.sol";

contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // withdraw-sender-rcv-EOA:
    // after a non-reverting withdraw(amount) originated by an EOA,
    // the ETH balance of the msg.sender is increased by amount wei.

    // PoC produced by GPT-5:
    // Let Alice (EOA) deposit 10 wei (credits[Alice]=10, contract balance=10).
    // Bob deposits 1 wei (contract balance=11).
    // Alice then calls withdraw(10).
    // The function sends 11 wei to Alice.
    // If Alice’s balance just before withdraw is B,
    // it becomes B + 11 after the non-reverting withdraw,
    // which is an increase of 11 wei, not amount (=10) wei.


    function test_withdraw_sender_rcv_EOA() public {
        // owner deploys the Bank contract
        address owner = address(123);
        vm.prank(owner);
        b = new Bank();

        // Alice deposits 10 wei
        address Alice = address(456);
        vm.deal(Alice, 10);
        vm.prank(Alice);
        b.deposit{value: 10}();

        // Bob deposits 1 wei
        address Bob = address(789);
        vm.deal(Bob, 10);
        vm.prank(Bob);
        b.deposit{value: 1}();

        uint Alice_balance_before = address(Alice).balance;

        // Alice withdraws 10 wei
        vm.prank(Alice);
        b.withdraw(10);

        uint Alice_balance_after = address(Alice).balance;

        // Alice's balance increases by 11 wei, not 10 wei
        assert(Alice_balance_after == Alice_balance_before + 11);

        // After a non-reverting withdraw(amount) originated by an EOA (here, Alice),
        // the ETH balance of the msg.sender (here, Alice) is NOT increased by amount wei.
        assert(Alice_balance_after != Alice_balance_before + 10);

    }

}