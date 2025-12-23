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
		tok0 = new ERC20(1000);
		tok1 = new ERC20(1000);
        lp = new LendingProtocol(tok0,tok1);
    }

    // rdm-xr-eq:
    // the exchange rate XR(T) of any token T handled by the `LendingProtocol` is preserved 
    // by any transaction `redeem(amount,T)`. 
    // Assume that T is a standard ERC20 token that do not charge fees on transfers.",

    // PoC produced by GPT-5:
	// - Let T = tok1.
	// - Alice: deposit(100, tok1). Now reserves[tok1]=100, sum_credits[tok1]=100, XR(tok1)=1e6.
	// - Bob: deposit(100, tok0) to have collateral; 
	// 	 then borrow(10, tok1). 
	// Now reserves[tok1]=90, sum_debits[tok1]=10, XR unchanged at 1e6; Bob is collateralized.
	// - Owner calls accrueInt(). Debit on tok1 becomes 11. XR(tok1) = ((90+11)*1e6)/100 = 1.01e6.
	// - Bob: repay(11, tok1). Now reserves[tok1]=101, sum_debits[tok1]=0, XR(tok1) remains 1.01e6.
	// - Alice: redeem(100, tok1). amount_rdm = 100 * 1.01e6 / 1e6 = 101, so require(reserves >= amount_rdm) holds. 
	// Post-state: reserves[tok1]=0, sum_credits[tok1]=0, hence XR(tok1)=1e6 by XR_def. 
	// Thus XR changed from 1.01e6 to 1e6, violating the property.

    function test_rdm_xr_eq(address a, address b) public {
		assertEq(tok0.totalSupply(), 1000);
		assertEq(tok0.balanceOf(address(this)), 1000);
	
		vm.assume(a != address(0) && a != address(this) && a != address(lp));
		vm.assume(b != address(0) && b != a && b != address(this) && b != address(lp));
			  
		tok1.transfer(a, 100);
		tok0.transfer(b, 100);
		tok1.transfer(b, 1);
		
		// Alice: deposit(100,tok1)	
		vm.prank(address(a));
		tok1.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok1));
	
		// Bob: deposit(100,tok0)	
		vm.prank(address(b));
		tok0.approve(address(lp), 100);
		vm.prank(address(b));
		lp.deposit(100, address(tok0));
	
		// Bob: borrow(10,tok1)	
		vm.prank(address(b));
		lp.borrow(10, address(tok1));
		assertEq(tok1.balanceOf(b), 11);
	
		lp.accrueInt();

		// Bob: repay(11,tok1)
		vm.prank(address(b));
		tok1.approve(address(lp), 11);
		vm.prank(address(b));
		lp.repay(11, address(tok1));

		uint xr1_before = lp.XR(address(tok1));
		assertEq(xr1_before, 1_010_000);
	
		// Alice: redeem(100:tok1)
		vm.prank(address(a));
		lp.redeem(100, address(tok1));
		assertEq(tok1.balanceOf(a), 101);		
	
		uint xr1_after = lp.XR(address(tok1));
		assertEq(xr1_after, 1_000_000);
    }
    
}
