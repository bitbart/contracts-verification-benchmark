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
	
    // dep-xr-eq-notrunc: the exchange rate XR(T) of any `token` handled by the `LendingProtocol` is
    // preserved by any transaction `deposit(amount,T)`.
    // Assume that T is a standard ERC20 token that do not charge fees on transfers.
    // Assume that arithmetic is exact: integer operations do not overflow and do not lead
    // to truncations.",
	
    // - Let T = tok0. Start with empty state (all zeros).
    // - User A deposits 100 T: deposit(100, T). Now reserves[T]=100, sum_credits[T]=100, XR(T)=1e6.
    // - User A redeems all credits: redeem(100, T). amount_rdm = 100 - 1 = 99, so reserves[T]=1, sum_credits[T]=0. XR(T) now equals 1e6 by the default branch (credits==0).
    //- User B deposits 1 T: deposit(1, T). Pre XR=1e6 ? amount_credit=1. Post-state: reserves[T]=2, sum_credits[T]=1. XR(T) = ((2 + 0) * 1e6) / 1 = 2e6 ? 1e6.
    //Hence, the deposit changed XR(T), violating the property.

    function test_dep_xr_eq_notrunc(address a, address b) public {
		assert(tok0.totalSupply() == 1000);
		assert(tok0.balanceOf(address(this)) == 1000);

		vm.assume(a != address(0) && a != address(lp));
		vm.assume(b != address(0) && b != address(lp));
		vm.assume(a != b);

		tok0.transfer(a, 100);
		tok0.transfer(b, 1);

		// Alice: deposit(100,tok0)	
		vm.prank(address(a));
		tok0.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));

		// Alice: redeem(100,T0)
		vm.prank(address(a));
		lp.redeem(100, address(tok0));

		// uint credits_a_tok0_before = lp.credit(address(tok0),a);
		uint xr0_before = lp.XR(address(tok0));	
		assertEq(xr0_before, 1_000_000);

		// Bob: deposit(1,tok0)	
		vm.prank(address(b));
		tok0.approve(address(lp), 1);	
		vm.prank(address(b));
		lp.deposit(1, address(tok0));

		// rdm-xr-eq violated: the XR(tok0) is not preserved		
		uint xr0_after = lp.XR(address(tok0));	
		assertEq(xr0_after, 2_000_000);
    }
}
