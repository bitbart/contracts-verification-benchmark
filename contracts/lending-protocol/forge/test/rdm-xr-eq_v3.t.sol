// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LendingProtocol} from "../src/LendingProtocol_v3.sol";
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
	// Consider token tok0.
	// 1) Bob deposits 100 tok0; reserves R=100; sum_credits C=100; sum_debits D=0.
	// 2) Alice deposits 200 tok0; now R=300; C=300; D=0; XR=1e6.
	// 3) Alice borrows 200 tok0; R=100; D=200; C=300; XR=1e6 (borrow keeps E=R+D constant).
	// 4) Owner calls accrueInt four times; D updates: 200?220?242?266?292. 
	// Now E=R+D=100+292=392; C=300; XR = floor(392e6/300) = 1,306,666.
	// 5) Bob calls redeem(1, tok0):
	// - Pre xr = 1,306,666\n   - amount_rdm = floor(1 * 1,306,666 / 1e6) = 1
	// - Reserves check passes (R=100 >= 1)
	// - Updates: R'=99, C'=299, D'=292
	// - Post XR' = floor(((99+292)*1e6)/299) = floor(391e6/299) = 1,307,692
	// XR changed from 1,306,666 to 1,307,692, violating the property.

    function test_rdm_xr_eq(address a, address b) public {
		assertEq(tok0.totalSupply(), 1000);
		assertEq(tok0.balanceOf(address(this)), 1000);
	
		vm.assume(a != address(0) && a != address(this) && a != address(lp));
		vm.assume(b != address(0) && b != a && b != address(this) && b != address(lp));
			  
		tok0.transfer(a, 200);
		tok0.transfer(b, 100);
	
		assertEq(tok0.balanceOf(a), 200);
		assertEq(tok0.balanceOf(b), 100);
	
		// Bob: deposit(100,tok0)	
		vm.prank(address(b));
		tok0.approve(address(lp), 100);
		vm.prank(address(b));
		lp.deposit(100, address(tok0));

		// Alice: deposit(200,tok0)	
		vm.prank(address(a));
		tok0.approve(address(lp), 200);	
		vm.prank(address(a));
		lp.deposit(200, address(tok0));
		
		// Alice: borrow(200,tok0)	
		vm.prank(address(a));
		lp.borrow(200, address(tok0));
	
		assertEq(tok0.balanceOf(a), 200);
	
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();

		uint xr0_before = lp.XR(address(tok0));
		assertEq(xr0_before, 1_306_666);
	
		// Bob: redeem(1,tok0)
		vm.prank(address(b));
		lp.redeem(1, address(tok0));
	
		uint xr0_after = lp.XR(address(tok0));
		// assertNotEq(xr0_after, xr0_before);
		assertEq(xr0_after, 1_307_692);
    }
}
