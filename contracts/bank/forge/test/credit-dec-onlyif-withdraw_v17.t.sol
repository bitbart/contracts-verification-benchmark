// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v17.sol";

contract Attack {
    Bank b;
    constructor(Bank _b) { b = _b; }
    function attack() public { b.withdraw(5 ether); }
    receive() external payable {}
}


contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }
    // credit-dec-onlyif-withdraw
    // if the credit of a user A is decreased after a transaction (of the Bank contract)
    // then that transaction must be a withdraw where A is the sender.

    // PoC produced by GPT-5:
    // - A first deposits 10 ether via deposit(), so credits[A] = 10.
    // - A then calls an intermediate contract Attack.attack(), which calls Bank.withdraw(5 ether).
    // - In Bank.withdraw: tx.origin = A, msg.sender = Attack. The require passes, credits[A] is decreased by 5, and 5 ether is sent to Attack.
    // - A’s credit decreased, but the withdraw call’s sender is Attack, not A.

    function test_credit_dec_onlyif_withdraw(address owner) public {
        // Owner deploys the Bank contract
        vm.prank(owner);
        b = new Bank();

        // Initialization
        address A = address(456);
        Attack _Attack = new Attack(b);

        // A first deposits 10 ether & then calls Attack.attack()
        vm.deal(address(A), 10 ether);
        vm.startPrank(address(A),address(A));
        b.deposit{value: 10 ether}();

        bytes32 slot_1 = keccak256(abi.encode(address(A), uint256(0)));
        uint A_credits_before = uint256(vm.load(address(b), slot_1));            // Credits of A before the Trxn

        // Trxn
        _Attack.attack();
        vm.stopPrank();

        bytes32 slot_2 = keccak256(abi.encode(address(A), uint256(0)));
        uint A_credits_after = uint256(vm.load(address(b), slot_2));               // Credits of A after the Trxn

        // The credits of A decreased after a transaction (of the Bank contract), but
        // the transaction is not a withdraw where A is the sender
        assert(A_credits_after < A_credits_before);
    }

}