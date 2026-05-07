// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LendingProtocol} from "../src/LendingProtocol_v7.sol";
import {ERC20} from "../src/lib/ERC20.sol";

contract LPTest is Test {
    LendingProtocol public lp;
    ERC20 public tok0;
    ERC20 public tok1;
    
    function setUp() public {
		tok0 = new ERC20(1200);
		tok1 = new ERC20(1000);
        lp = new LendingProtocol(tok0,tok1);
    }

    // rpy_tokens: if a user A performs a non-reverting `repay(amount,T)`, then after the transaction:
    // (1) the T balance in the `LendingProtocol` is increased by `amt`;
    // the T balance of A is decreased by `amt`.
    // Assume that T is a standard ERC20 token that do not charge fees on transfers

    // - Let T = tok0.
    // - Setup:
    //   1) User B deposits 100 tok1: deposit(100, address(tok1)) to provide tok1 reserves.
    //   2) User A deposits 100 tok0: deposit(100, address(tok0)).
    //   3) User A borrows 10 tok1: borrow(10, address(tok1)) (collateralization holds).
    //   4) User A approves the protocol to spend 5 tok1 via ERC20 approve on tok1.
    // - Action: User A calls repay(5, address(tok0)).
    // - Outcome: The call does not revert because repay overwrites the token to tok1.
    // The protocol pulls 5 tok1 from A and increases its tok1 balance by 5.
    // The tok0 balances of both A and the protocol remain unchanged.
    // This violates the property that the T (= tok0) balances change by amt.
    
    function test_rpy_tokens(address a, address b) public {
		// assert(tok0.totalSupply() == 1200);
		// assert(tok0.balanceOf(address(this)) == 1200);

		vm.assume(a != address(0) && a != address(lp) && a != address(this));
		vm.assume(b != address(0) && b != address(lp) && b != address(this));
		vm.assume(a != b);

		tok0.transfer(a, 100);
		tok1.transfer(b, 100);
		tok1.transfer(a, 5);

		// Bob: deposit(100,T1)	
		vm.prank(address(b));
		tok1.approve(address(lp), 100);	
		vm.prank(address(b));
		lp.deposit(100, address(tok1));

		// Alice: deposit(100,T0)	
		vm.prank(address(a));
		tok0.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));

		// Alice: borrow(10,T1)	
		vm.prank(address(a));
		lp.borrow(10, address(tok1));

		uint balance0_a_before = tok0.balanceOf(a);
		assertEq(balance0_a_before, 0);

		// Alice: repay(5,T0)		
		vm.prank(address(a));
		tok1.approve(address(lp), 5);	
		vm.prank(address(a));
		lp.repay(5, address(tok0));

		// (2) is violated: the balance of A in T0 is NOT decreased by 5;		
		uint balance0_a_after = tok0.balanceOf(a);
		assertEq(balance0_a_after, 0);
    }
}
