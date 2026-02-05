// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v6.sol";

contract A {
    Bank b;
    constructor(Bank _b) { b = _b; }
    receive() external payable {b.deposit{value: 3 wei}(); }
}


contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // assets-dec-onlyif-deposit:
    // if the ETH balance of a user A is decreased after a transaction (of the Bank contract),
    // then that transaction must be a `deposit` where A is the sender.

    // PoC produced by GPT-5:
    // - Pre-state: 
        // - credits[A] = 1 wei
        // - Bank’s ETH balance ≥ 2 wei (funded earlier by any account)
        // - A’s ETH balance ≥ 3 wei (A is a contract with a payable fallback/receive)
    // - Transaction:
        // A calls withdraw(1 wei).
        // - Bank subtracts credits[A] by 1 wei.
        // - Bank sends 2 wei (amount + 1) to A. In A’s receive/fallback, A calls Bank.deposit{value: 3 wei}().
    // - Post-state:
        // A’s ETH balance goes from ≥ 3 wei to ≥ 3 + 2 − 3 = ≥ 2 wei, i.e., it decreased by 1 wei after this transaction.
        // But the transaction was withdraw, not a deposit by A.


    function test_assets_dec_onlyif_deposit(address owner) public {
        // Owner deploys the Bank contract
        vm.prank(owner);
        b = new Bank();

        // Initialization
        A contractA = new A(b);
        
        // Pre-state
        vm.deal(address(b), 2);                 // Bank’s ETH balance ≥ 2 wei

        vm.deal(address(contractA), 4);         //A’s ETH balance ≥ 3 wei
        vm.prank(address(contractA));
        b.deposit{value: 1}();                  // credits[A] = 1 wei

        uint A_balance_before = address(contractA).balance;    // Balance of A before Transaction

        // Transaction
        vm.prank(address(contractA));
        b.withdraw(1);                          // A calls withdraw(1 wei)

        uint A_balance_after = address(contractA).balance;    // Balance of A after Transaction

        // Post-state
        // Balance of A decreases after a transaction of the Bank contract,
        // but the transaction is not a deposit where A is the sender!
        assert(A_balance_after < A_balance_before);
    }


}