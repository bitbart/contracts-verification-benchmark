// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v13.sol";

contract A {
    address B;
    constructor(address _b) { B = _b; }
    receive() external payable { payable(B).call{value: 2 ether}(""); }
}

contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // assets-dec-onlyif-deposit:
    // if the ETH balance of a user A is decreased after a transaction (of the Bank contract),
    // then that transaction must be a `deposit` where A is the sender.

    // PoC produced by GPT-5:
    // - Setup: Let A be a smart contract with receive() external payable that immediately sends 2 ETH to address B (e.g., payable(B).call{value: 2 ether}("""");).
    //   Fund A with at least 2 ETH from outside.
    //   Have A previously deposit enough into Bank so credits[A] >= 1 ether.
    // - Transaction: A calls Bank.withdraw(1 ether).
    // - Execution: Bank reduces credits[A] and calls A with 1 ether. A’s receive runs and sends 2 ether to B.
    // - Result: After the transaction, A’s balance decreased by 1 ether (received 1, sent 2), yet the transaction was withdraw, not a deposit by A.


    function test_assets_dec_onlyif_deposit() public {
        // Initialization
        address owner = address(123);
        address userB = address(456);
        A contractA = new A(userB);

        // Owner deploys the Bank contract
        vm.prank(owner);
        b = new Bank();

        // Funding A with atleast 2 ETH
        vm.deal(address(contractA), 3 ether);

        // Make sure credits[A] >= 1 ether
        vm.prank(address(contractA));
        b.deposit{value: 2 ether}();

        uint A_balance_before = address(contractA).balance;        // Balance of A before the Trxn

        // Trxn: A withdraws 1 ETH from Bank
        vm.prank(address(contractA));
        b.withdraw(1 ether);

        uint A_balance_after = address(contractA).balance;        // Balance of A after the Trxn

        // Balance of A decreases after a transaction of the Bank contract,
        // but the transaction is not a deposit where A is the sender
        assert(A_balance_after < A_balance_before);
    }

}