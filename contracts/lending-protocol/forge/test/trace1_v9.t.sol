// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LendingProtocol} from "../src/LendingProtocol_v9.sol";
import {ERC20} from "../src/lib/ERC20.sol";
import {console} from "forge-std/console.sol";

contract LPTest is Test {
    LendingProtocol public lp;
    ERC20 public tok0;
    ERC20 public tok1;
    
    function test_trace1() public {
		tok0 = new ERC20(10000000000);
		tok1 = new ERC20(10000000000);
		address owner = address(0x04834);
		vm.prank(owner);
        lp = new LendingProtocol(tok0,tok1);

        //  "From the initial state, consider the sequence of transactions: 
		// (1) A deposits 50 units of T0, 
		// (2) B deposits 50 units of T1, 
		// (3) B borrows 30 units of T0. 
		// Then, after that sequence: 
		// (1) the contract has reserves of 20 units of T0 and 50 units of T1, 
		// (2) A has 50 credits of T0, 0 debits of T1 and 0 debits, 
		// (3) B has 50 credits of T1 and 30 debits of T0",

		assert(tok0.totalSupply() == 10000000000);
		assert(tok0.balanceOf(address(this)) == 10000000000);
		assert(tok1.totalSupply() == 10000000000);
		assert(tok1.balanceOf(address(this)) == 10000000000);


        address a = address(0x111);
        address b = address(0x222);

		tok0.transfer(a, 200000000);
		tok0.transfer(b, 200000000);
		tok1.transfer(a, 200000000);
		tok1.transfer(b, 200000000);

		// (1) A deposits 50 units of T0, 
		vm.prank(address(a));
		tok0.approve(address(lp), 50);	
		vm.prank(address(a));
		lp.deposit(50, address(tok0));

		// (2) B deposits 50 units of T1, 
		vm.prank(address(b));
		tok1.approve(address(lp), 50);	
		vm.prank(address(b));
		lp.deposit(50, address(tok1));

		// (3) B borrows 30 units of T0. 
		vm.prank(address(b));
		lp.borrow(30, address(tok0));

		console.log(" reserves[T0]=%d",lp.reserves(address(tok0)));
		console.log(" credits[T0][a]=%d",lp.credit(address(tok0),a));
		console.log(" credits[T0][b]=%d",lp.credit(address(tok0),b));
		console.log(" debts[T0][a]=%d",lp.debit(address(tok0),a));
		console.log(" debts[T0][b]=%d",lp.debit(address(tok0),b));

		console.log(" reserves[T1]=%d",lp.reserves(address(tok1)));
		console.log(" credits[T1][a]=%d",lp.credit(address(tok1),a));
		console.log(" credits[T1][b]=%d",lp.credit(address(tok1),b));
		console.log(" debts[T1][a]=%d",lp.debit(address(tok1),a));
		console.log(" debts[T1][b]=%d",lp.debit(address(tok1),b));

		// (1) the contract has reserves of 20 units of T0 and 50 units of T1, 
		assertEq(lp.reserves(address(tok0)), 20);
		assertEq(lp.reserves(address(tok1)), 50);
		// (2) A has 50 credits of T0, 0 debits of T1 and 0 debits, 
		assertEq(lp.credit(address(tok0),a), 50);
		assertEq(lp.debit(address(tok1),a), 0);
		assertEq(lp.debit(address(tok0),a), 0);
		// (3) B has 50 credits of T1 and 30 debits of T0",
		assertEq(lp.credit(address(tok1),b), 50);
		assertEq(lp.debit(address(tok1),b), 0);
		assertEq(lp.debit(address(tok0),b), 30);
    }

}
