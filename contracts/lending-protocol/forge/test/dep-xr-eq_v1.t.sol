// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LendingProtocol} from "../src/LendingProtocol_v1.sol";
import {ERC20} from "../src/lib/ERC20.sol";

contract LPTest is Test {
    LendingProtocol public lp;
    ERC20 public tok0;
    ERC20 public tok1;
    
    function setUp() public {
		tok0 = new ERC20(1000);
		tok1 = new ERC20(1000);
        lp = new LendingProtocol(tok0,tok1);
    }

	// dep-xr-eq: 
	// the exchange rate XR(T) of any token handled by the LendingProtocol is preserved 
	// by any transaction deposit(amount,T). 
	// Assume that T is a standard ERC20 token that do not charge fees on transfers.

	// PoC produced by GPT-5:
	// - Let T = tok0. Start from fresh deployment (all zeros).
	// - Alice: deposit(100, tok0) → reserves[tok0]=100, sum_credits[tok0]=100, XR(tok0)=1e6.
	// - Bob: deposit(1, tok1) → gives Bob collateral (XR(tok1)=1e6; price(tok1)=2).
	// - Bob: borrow(10, tok0) → reserves[tok0]=90, sum_debits[tok0]=10, Bob collateralized.
	// - Owner: accrueInt() → debit[tok0][Bob] increases by 1 (10% of 10 with 1e6 scaling), so sum_debits[tok0]=11. Now XR(tok0) = (90 + 11) * 1e6 / 100 = 1,010,000.
	// - Carol: deposit(1, tok0). Pre-state xr = 1,010,000, so amount_credit = floor(1*1e6 / 1,010,000) = 0. Reserves[tok0] increases to 91; sum_credits[tok0] stays 100. XR(tok0) becomes (91 + 11) * 1e6 / 100 = 1,020,000.
	// Thus, XR(tok0) changed during a deposit, contradicting the property."

    function test_dep_xr_eq(address a, address b, address c) public {
		assert(tok0.totalSupply() == 1000);
		assert(tok0.balanceOf(address(this)) == 1000);
	
		vm.assume(a != address(0) && a != address(this) && a != address(lp));
		vm.assume(b != address(0) && b != a && b != address(this) && b != address(lp));
		vm.assume(c != address(0) && c != a && c != b && c != address(this) && c != address(lp));
			  
		tok0.transfer(a, 100);
		tok1.transfer(b, 100);
		tok0.transfer(c, 100);
	
		assertEq(tok0.balanceOf(a), 100);
		assertEq(tok1.balanceOf(b), 100);
	
		// Alice: deposit(100,tok0)	
		vm.prank(address(a));
		tok0.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));
	
		// Bob: deposit(1,tok1)	
		vm.prank(address(b));
		tok1.approve(address(lp), 1);
		vm.prank(address(b));
		lp.deposit(1, address(tok1));
	
		// Bob: borrow(10,tok0)	
		vm.prank(address(b));
		lp.borrow(10, address(tok0));
	
		assertEq(tok0.balanceOf(b), 10);
	
		lp.accrueInt();
	
		uint xr0_before = lp.XR(address(tok0));
		assertEq(xr0_before, 1_010_000);
	
		// Carol: deposit(1:tok0)
		vm.prank(address(c));
		tok0.approve(address(lp), 1);	
		vm.prank(address(c));
		lp.deposit(1, address(tok0));
	
		uint xr0_after = lp.XR(address(tok0));
		// assertNotEq(xr0_after, xr0_before);
		assertEq(lp.XR(address(tok0)), 1_020_000);
    }
    
}
