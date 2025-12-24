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
	// - Let T = tok1. Start with empty protocol.
	// - Alice deposits 100 T: reserves=100, sum_credits=100, sum_debits=0, XR=1e6.
	// - Alice borrows 50 T: reserves=50, sum_debits=50, XR=1e6.
	// - Owner calls accrueInt (10%): sum_debits=55, reserves=50, XR=1.05e6.
	// - Alice repays 55 T via repay(55, T). 
	// Note repay forces token_addr=tok1: reserves=105, sum_debits=0, XR remains 1.05e6.
	// - Alice redeems all her credits: redeem(100, T). amount_rdm = 100 * 1.05e6 / 1e6 = 105, allowed since reserves=105. 
	// Post-state: reserves=0, sum_credits=0, so XR(T) becomes 1e6. XR decreased from 1.05e6 to 1e6.

    function test_xr_increasing(address a, address b) public {
	
		vm.assume(a != address(0) && a != address(this) && a != address(lp));
		vm.assume(b != address(0) && b != a && b != address(this) && b != address(lp));
			  
		tok1.transfer(a, 105);
		
		// Alice: deposit(100,tok1)	
		vm.prank(address(a));
		tok1.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok1));
		
		// Alice: borrow(50,tok1)	
		vm.prank(address(a));
		lp.borrow(50, address(tok1));
		
		lp.accrueInt();

		// Alice: repay(55,tok1)	
		vm.prank(address(a));
		tok1.approve(address(lp), 55);	
		vm.prank(address(a));
		lp.repay(55, address(tok1));

		uint xr1_before = lp.XR(address(tok1));
		assertEq(xr1_before, 1_050_000);

		// Alice: redeem(100,tok1)
		vm.prank(address(a));
		lp.redeem(100, address(tok1));
		
		uint xr1_after = lp.XR(address(tok1));
		assertEq(xr1_after, 1_000_000);

		// This PoC fails, since XR does not decrease!
		assertLt(xr1_after, xr1_before);
    }
}
