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
    
    // rdm-state: if a user A performs a non-reverting `redeem(amount,T)`, then after the transaction,
    // (1) the `LendingProtocol` reserves of T are decreased by `amt * XR(T) / 1e6` (where XR(T) is that in the pre-state);
    // (2) the credits of A in T are decreased by `amt`;
    // (3) the credits of A in all tokens different from T are preserved. Assume that T is a standard ERC20 token.

    // PoC produced by GPT-5:
    // Let T = tok0. Pre-state: reserves[T] = 1000, sum_credits[T] = 1000, sum_debits[T] = 0, credit[T][Alice] = 100, and Alice has no debt. Then XR(T) = ((1000 + 0) * 1e6) / 1000 = 1e6.
    // Alice calls redeem(10, T). The call succeeds. The contract computes amount_rdm = (10 * 1e6) / 1e6 - 1 = 9 and reduces reserves by 9, not by 10 as the property claims.
    // Credits: credit[T][Alice] decreases by 10; credits in other tokens remain unchanged.
    
    function test_rdm_state(address a, address b) public {
		assert(tok0.totalSupply() == 1000);
		assert(tok0.balanceOf(address(this)) == 1000);
	
		vm.assume(a != address(0));
		vm.assume(b != address(0));
		vm.assume(a != b);
			
		tok0.transfer(a, 100);
		tok0.transfer(b, 900);
	
		// Alice: deposit(100,tok0)	
		vm.prank(address(a));
		tok0.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));
	
		// Bob: deposit(900,tok0)	
		vm.prank(address(b));
		tok0.approve(address(lp), 900);	
		vm.prank(address(b));
		lp.deposit(900, address(tok0));
		
		// uint credits_a_tok0_before = lp.credit(address(tok0),a);
		uint reserves0_before = lp.reserves(address(tok0));	
		assertEq(reserves0_before, 1000);
		
		// Alice: redeem(10,T0)
		uint amt = 10;
		vm.prank(address(a));
		lp.redeem(amt, address(tok0));
	
		uint reserves0_after = lp.reserves(address(tok0));
	
		// (2) is violated: the credits of A in T are NOT decreased by `amt`;	
		assertEq(reserves0_after, 991);
	
		// assertEq(reserves0_after, reserves0_before - amt);	
    }

}
