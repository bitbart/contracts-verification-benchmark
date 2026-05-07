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

    // rdm-xr-eq:
    // the exchange rate XR(T) of any token T handled by the `LendingProtocol` is preserved 
    // by any transaction `redeem(amount,T)`. 
    // Assume that T is a standard ERC20 token that do not charge fees on transfers.",

    // PoC produced by GPT-5:
    //- Let T = tok0.
    //- Alice deposits 100 T (sum_credits[T]=100, reserves[T]=100, XR(T)=1e6).
    // - Bob deposits collateral in tok1 (e.g., 100 tok1) and borrows 10 T (reserves[T]=90, sum_debits[T]=10, XR(T)=1e6).
    // - Owner calls accrueInt(); Bob's debt in T becomes 11 (10% interest), reserves[T]=90, sum_debits[T]=11, so XR(T) = (90+11)*1e6/100 = 1.01e6.
    //- Bob repays 11 T; reserves[T]=101, sum_debits[T]=0, XR(T)=1.01e6.
    //- Alice calls redeem(100, T). amount_rdm = 100 * 1.01e6 / 1e6 = 101, allowed since reserves[T]=101. Post-state: sum_credits[T]=0, reserves[T]=0. XR(T) becomes 1e6 by XR_def's default branch, not 1.01e6."

    function test_rdm_xr_eq(address a, address b) public {
		assertEq(tok0.totalSupply(), 1000);
		assertEq(tok0.balanceOf(address(this)), 1000);
	
		vm.assume(a != address(0) && a != address(this) && a != address(lp));
		vm.assume(b != address(0) && b != a && b != address(this) && b != address(lp));
			  
		tok0.transfer(a, 100);
		tok0.transfer(b, 1);
		tok1.transfer(b, 100);
	
		assertEq(tok0.balanceOf(a), 100);
		assertEq(tok1.balanceOf(b), 100);
	
		// Alice: deposit(100,tok0)	
		vm.prank(address(a));
		tok0.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));
	
		// Bob: deposit(100,tok1)	
		vm.prank(address(b));
		tok1.approve(address(lp), 100);
		vm.prank(address(b));
		lp.deposit(100, address(tok1));
	
		// Bob: borrow(10,tok0)	
		vm.prank(address(b));
		lp.borrow(10, address(tok0));
	
		assertEq(tok0.balanceOf(b), 11);
	
		lp.accrueInt();

		// Bob: repay(11,tok0)
		vm.prank(address(b));
		tok0.approve(address(lp), 11);
		vm.prank(address(b));
		lp.repay(11, address(tok0));

		uint xr0_before = lp.XR(address(tok0));
		assertEq(xr0_before, 1_010_000);
	
		// Alice: redeem(100:tok0)
		vm.prank(address(a));
		tok0.approve(address(lp), 1);	
		vm.prank(address(a));
		lp.redeem(100, address(tok0));
		assertEq(tok0.balanceOf(a), 101);
	
		uint xr0_after = lp.XR(address(tok0));
		// assertNotEq(xr0_after, xr0_before);
		assertEq(xr0_after, 1_000_000);
    }
    
}
