// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LendingProtocol} from "../src/LendingProtocol_v4.sol";
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
	
    // rdm-xr-eq: the exchange rate XR(T) of any token T handled by the `LendingProtocol` is preserved
    // by any transaction `redeem(amount,T)`.
    // Assume that T is a standard ERC20 token that do not charge fees on transfers.

    // PoC produced by GPT-5:   
    // - Let T = tok0. Initially, no debt and no credits.
    // - Alice deposits 100 T: reserves[T] = 100, sum_credits[T] = 100, so XR(T) = (100 * 1e6) / 100 = 1_000_000.
    // - Alice calls redeem(50, T). Pre-state xr = 1_000_000, so amount_rdm = (50 * 1_000_000)/1_000_000 - 1 = 49. Post-state: reserves[T] = 51, sum_credits[T] = 50.
    // - New XR(T) = (51 * 1e6) / 50 = 1_020_000 ? 1_000_000.
    // Thus XR is not preserved by redeem.

    function test_rdm_xr_eq(address a, address b) public {
		assert(tok0.totalSupply() == 1000);
		assert(tok0.balanceOf(address(this)) == 1000);
	
		vm.assume(a != address(0) && a != address(this) && a != address(lp));
		vm.assume(b != address(0) && b != address(this) && b != address(lp));
		vm.assume(a != b);
			
		tok0.transfer(a, 100);
		// tok0.transfer(b, 900);
	
		// Alice: deposit(100,tok0)	
		vm.prank(address(a));
		tok0.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));
		
		// uint credits_a_tok0_before = lp.credit(address(tok0),a);
		uint xr0_before = lp.XR(address(tok0));	
		assertEq(xr0_before, 1_000_000);
		
		// Alice: redeem(50,T0)
		uint amt = 50;
		vm.prank(address(a));
		lp.redeem(amt, address(tok0));
	
		// rdm-xr-eq violated: the XR(tok0) is not preserved	
		
		uint xr0_after = lp.XR(address(tok0));	
		assertEq(xr0_after, 1_020_000);
    }
}
