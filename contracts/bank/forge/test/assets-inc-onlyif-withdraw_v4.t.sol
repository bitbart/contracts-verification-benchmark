// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v4.sol";

contract M {
    address A;
    constructor(address _a) { A = _a; }
    receive() external payable { payable(A).call{value: msg.value}(""); }   // M immediately forwards the received ETH to A
}

contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }
    // assets-inc-onlyif-withdraw
    // if the ETH balance of a user A is increased after a transaction (of the Bank contract)
    // then that transaction must be a withdraw where A is the sender.

    // PoC produced by GPT-5:
    // - Let M be a contract and A be any address (not the Bank).
    // - M first calls deposit with value V ≥ 2 wei, so credits[M] increases by V−1.
    // - M then calls withdraw(V−1). Bank executes msg.sender.call{value: V−1} to M.
    // - In M’s receive/fallback, M immediately forwards the received ETH to A.
    // - After this single withdraw transaction, A’s ETH balance increased, but A was not the sender of the transaction.


    function test_assets_inc_onlyif_withdraw(address owner) public {
        // Initialization
        address A = address(123);
        vm.assume(A != owner && owner != address(0));
        M contractM = new M(A);

        // Owner deploys the Bank contract
        vm.prank(owner);
        b = new Bank();

        // M first calls deposit with value V ≥ 2 wei & M then calls withdraw(V−1)
        vm.deal(address(contractM), 1 ether);
        vm.startPrank(address(contractM));
        b.deposit{value: 2}();

        uint A_balance_before = address(A).balance;        // Balance of A before the Trxn

        // Trxn: M withdraws from Bank
        b.withdraw(1);                      
        vm.stopPrank();

        uint A_balance_after = address(A).balance;        // Balance of A after the Trxn
    
        // Balance of A increases after a transaction (of the Bank contract),
        // but that transaction is not a withdraw where A is the sender
        assert(A_balance_before < A_balance_after);
    }

}