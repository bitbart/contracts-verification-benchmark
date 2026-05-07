// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v9.sol";


contract A {
    Bank b;
    constructor(Bank _b) { b = _b; }
    function attack() public { b.withdraw(1 ether); }
    receive() external payable { b.deposit{value: 0}(); }
}

contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // deposit-not-revert:
    // a deposit transaction never reverts

    // PoC produced by GPT-5:
    // - Step 1 (setup):
        // An attacker contract A first deposits 1 ether into Bank so credits[A] = 1 ether
        // (a separate successful transaction calling deposit).
    // - Step 2 (attack transaction):
        // EOA calls A.attack(), which calls Bank.withdraw(1 ether).
        // During Bank.withdraw, after debiting credits[A], it executes (bool success,) = msg.sender.call{value: amount}("""").
        // This calls A’s receive/fallback.
        // In A’s receive/fallback, A calls Bank.deposit{value: 0}().
        // Because withdraw is still executing under the nonReentrant modifier, Bank.deposit’s nonReentrant modifier detects re-entry and reverts.
        // Hence, this deposit call reverts, violating the property.


    function test_deposit_not_revert() public {
        // Initialization
        address owner = address(123);
        address EOA = address(456);
        
        // owner deploys the Bank contract
        vm.prank(owner);
        b = new Bank();
        
        A contractA = new A(b);

        // Funding Attacker A
        vm.deal(address(contractA), 1 ether);

        // A deposits 1 ether
        vm.prank(address(contractA));
        b.deposit{value: 1 ether}();

        // EOA calls A.attack()
        // The deposit transaction DOES revert
        vm.expectRevert();
        vm.prank(address(EOA));
        contractA.attack();        
    }

}