// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LendingProtocol} from "../src/LendingProtocol_v2.sol";
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
	// - Let T = tok0.
	// - Alice deposits 100 tok0: reserves[T]=100, sum_credits[T]=100, XR(T)=1,000,000.
	// - Bob deposits 1 tok1 (any positive amount suffices for collateral given tLiq), 
	//   then borrows 60 tok0: reserves[T]=40, sum_debits[T]=60, sum_credits[T]=100. Borrow passes collateral check.
	// - Wait enough blocks so that XR's view-time interest accrual increases total debt by 1 
	//   (e.g., last_global_update at borrow, then after ~166,670 blocks, XR() computes updated total debt = 61 using _calculate_linear_interest()).
	// - Pre-redeem: XR(T)=floor(((40 + 61) * 1e6) / 100) = 1,010,000.
	// - Alice calls redeem(10, T). amount_rdm = floor(10 * 1,010,000 / 1,000,000) = 10; reserves[T] ? 30; sum_credits[T] ? 90. 
	// The call succeeds (reserves check passes; Alice has no debt, so collateralization check passes).
	// - Post-redeem: XR(T)=floor(((30 + 61) * 1e6) / 90) = 1,011,111 ? 1,010,000.
	// Thus, redeem changed XR(T), violating the stated property.

    function test_rdm_xr_eq(address a, address b) public {
		assertEq(tok0.totalSupply(), 1000);
		assertEq(tok0.balanceOf(address(this)), 1000);
	
		vm.assume(a != address(0) && a != address(this) && a != address(lp));
		vm.assume(b != address(0) && b != a && b != address(this) && b != address(lp));
			  
		tok0.transfer(a, 100);
		tok1.transfer(b, 100);
	
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
	
		// Bob: borrow(60,tok0)	
		vm.prank(address(b));
		lp.borrow(60, address(tok0));
		assertEq(tok0.balanceOf(b), 60);
	
		vm.roll(166_671);
		uint accrued_debit0_b = lp.getAccruedDebt(address(tok0),b);
		assertEq(accrued_debit0_b, 61);

		uint xr0_before = lp.XR(address(tok0));
		assertEq(xr0_before, 1_010_000);
	
		// Alice: redeem(10:tok0)
		vm.prank(address(a));
		lp.redeem(10, address(tok0));
		assertEq(tok0.balanceOf(a), 10);
	
		uint xr0_after = lp.XR(address(tok0));
		// assertNotEq(xr0_after, xr0_before);
		assertEq(xr0_after, 1_011_111);
    }
}
