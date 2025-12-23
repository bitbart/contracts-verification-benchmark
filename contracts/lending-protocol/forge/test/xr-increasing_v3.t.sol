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
		tok0 = new ERC20(1_003_002_998);
		tok1 = new ERC20(1000);
        lp = new LendingProtocol(tok0,tok1);
    }

    // xr-increasing:
	// Let T be a token handled by the lending protocol, and assume that T is a standard ERC20 token. 
	// Then, deposit, borrow, repay and redeem transactions do not decrease XR(T). 
	// Assume that before performing the transaction, the interests on T have already been accrued 
	// for all users affected by the transaction.

    // PoC produced by GPT-5:
	// - Token T = tok0.
	// - Initial: User B deposits 1001 tok0 ? reserves=1001, sum_credits=1001, sum_debits=0, XR=1,000,000.
	// - User A deposits sufficient tok1 as collateral (e.g., 100 tok1; tok1 price=2) so she can borrow tok0.
	// - User A borrows 10 tok0 ? reserves=991, sum_debits=10, sum_credits=1001, XR remains 1,000,000.
	// - Owner calls accrueInt() ? sum_debits=11 (10% of 10), reserves=991. Now XR_pre = floor((991+11)*1e6/1001) = floor(1002e6/1001) = 1,000,999 (not exact due to flooring).
	// - A user deposits amount a = 1,003,000,998 tok0.
	// 	 - Pre XR used in deposit is xr = 1,000,999.
	// 	 - Minted credits = (a * 1e6)/xr = (1,003,000,998 * 1,000,000)/1,000,999 = 1,002,000,000.
	// 	 - Post-state: reserves' = 991 + 1,003,000,998 = 1,003,001,989; sum_debits' = 11; sum_credits' = 1001 + 1,002,000,000 = 1,002,001,001.
	// 	 - XR_post = floor((reserves' + sum_debits')*1e6 / sum_credits') = floor(1,003,002,000e6 / 1,002,001,001), which is strictly less than 1,000,999 (the pre-state XR), because the minted credits exceeded the ideal amount by 1 due to rounding.
	// Thus, deposit decreases XR(T), violating the property."

    function test_rdm_xr_eq(address a, address b) public {
	
		vm.assume(a != address(0) && a != address(this) && a != address(lp));
		vm.assume(b != address(0) && b != a && b != address(this) && b != address(lp));
			  
		tok1.transfer(a, 100);
		tok0.transfer(b, 1_003_000_998 + 1001);
		
		// Bob: deposit(1001,tok0)	
		vm.prank(address(b));
		tok0.approve(address(lp), 1001);
		vm.prank(address(b));
		lp.deposit(1001, address(tok0));

		// Alice: deposit(100,tok1)	
		vm.prank(address(a));
		tok1.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok1));
		
		// Alice: borrow(10,tok0)	
		vm.prank(address(a));
		lp.borrow(10, address(tok0));
	
		assertEq(tok0.balanceOf(a), 10);
	
		lp.accrueInt();

		uint xr0_before = lp.XR(address(tok0));
		assertEq(xr0_before, 1_000_999);

		// Bob: deposit(1_003_000_998,tok0)
		vm.prank(address(b));
		tok0.approve(address(lp), 1_003_000_998);
		vm.prank(address(b));
		lp.deposit(1_003_000_998, address(tok0));
		
		assertEq(lp.reserves(address(tok0)), 1_003_000_998 + 1001 - 10);

		uint xr0_after = lp.XR(address(tok0));
		assertEq(xr0_after, 1_000_999);
		// This PoC fails, since XR does not decrease!
		assertLt(xr0_after, xr0_before);
    }
}
