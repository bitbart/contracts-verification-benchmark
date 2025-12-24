// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LendingProtocol} from "../src/LendingProtocol_v1.sol";
import {ERC20} from "../src/lib/ERC20.sol";
import {console} from "forge-std/console.sol";

contract LPTest is Test {
    LendingProtocol public lp;
    ERC20 public tok0;
    ERC20 public tok1;
    
    function test_rdm_additivity() public {
		tok0 = new ERC20(10000);
		tok1 = new ERC20(10000);
		address owner = address(0x04834);
		vm.prank(owner);
        lp = new LendingProtocol(tok0,tok1);

	// - Tokens: T = tok0.
	// - Setup:
	//   1) A deposits 1000 tok0. State: reserves=1000, sum_credits=1000, sum_debits=0, XR=1,000,000.
	//   2) B deposits 1 tok1 (to pass collateralization) and borrows 1000 tok0. State: reserves=0, sum_debits=1000, sum_credits=1000.
	//   3) Owner calls accrueInt 6 times. Debit grows: 1000 → 1100 → 1210 → 1331 → 1464 → 1610 → 1771. Now XR(tok0) = floor((0+1771)*1e6/1000) = 1,771,000.
	//   4) Some S deposits 2 tok0. Credits minted = floor(2*1e6/1,771,000) = 1. State: reserves=2, sum_credits=1001; XR = floor((2+1771)*1e6/1001) = 1,771,228.
	// - Two consecutive redeems by A:
	//   - First redeem(1, tok0): amount_rdm = floor(1,771,228/1e6) = 1. New state: reserves=1, sum_credits=1000; XR = floor((1+1771)*1e6/1000)=1,772,000.
	//   - Second redeem(1, tok0): amount_rdm = floor(1,772,000/1e6) = 1. New state: reserves=0, sum_credits=999. Total received by A: 2 tok0. Both calls succeed; A has no debt so collateralization checks pass.
	// - Single redeem attempt:
	//   - redeem(2, tok0) from the state before the two calls (reserves=2, XR=1,771,228) requires amount_rdm = floor(2*1,771,228/1e6) = 3, but reserves=2, so it reverts with """"Redeem: insufficient reserves.""""
	// Thus, two successful consecutive redeems cannot be replicated by a single redeem of the summed amount.

		assert(tok0.totalSupply() == 10000);
		assert(tok0.balanceOf(address(this)) == 10000);
		assert(tok1.totalSupply() == 10000);
		assert(tok1.balanceOf(address(this)) == 10000);


        address a = address(0x111);
        address b = address(0x222);
        address s = address(0x333);

		//uint256 my_blocknum1 = blocknum1_input;
		//uint256 my_blocknum2 = blocknum2_input;


		tok0.transfer(a, 1000);
		tok0.transfer(b, 1000);
		tok0.transfer(s, 1000);
		tok1.transfer(b, 1000);

		//   1) A deposits 1000 tok0. State: reserves=1000, sum_credits=1000, sum_debits=0, XR=1,000,000.

		vm.prank(address(a));
		tok0.approve(address(lp), 1000);	
		vm.prank(address(a));
		lp.deposit(1000, address(tok0));

		//   2) B deposits 1 tok1 (to pass collateralization) and borrows 1000 tok0. State: reserves=0, sum_debits=1000, sum_credits=1000.
		vm.prank(address(b));
		tok1.approve(address(lp), 1);	
		vm.prank(address(b));
		lp.deposit(1, address(tok1));

		vm.prank(address(b));
		lp.borrow(1000, address(tok0));
		uint256 new_XR = lp.XR(address(tok0));
		
		//   3) Owner calls accrueInt 6 times. Debit grows: 1000 → 1100 → 1210 → 1331 → 1464 → 1610 → 1771. Now XR(tok0) = floor((0+1771)*1e6/1000) = 1,771,000.
		vm.startPrank(address(owner));
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();
		vm.stopPrank();
		console.log(" 3)  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" 3)  sum_credits[T]=%d",lp.credit(address(tok0),a)+lp.credit(address(tok0),b)+ 	lp.credit(address(tok0),s));
		console.log(" 3)  sum_debits[T]=%d",lp.debit(address(tok0),a)+lp.debit(address(tok0),b)+ 	lp.debit(address(tok0),s));
		console.log(" 3)  lp.XR[T]=%d",lp.XR(address(tok0)));

		//   4) Some S deposits 2 tok0. Credits minted = floor(2*1e6/1,771,000) = 1. State: reserves=2, sum_credits=1001; XR = floor((2+1771)*1e6/1001) = 1,771,228.
		vm.prank(address(s));
		tok0.approve(address(lp), 2);	
		vm.prank(address(s));
		lp.deposit(2, address(tok0));

		console.log(" 4)  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" 4)  sum_credits[T]=%d",lp.credit(address(tok0),a)+lp.credit(address(tok0),b)+ 	lp.credit(address(tok0),s));
		console.log(" 4)  sum_debits[T]=%d",lp.debit(address(tok0),a)+lp.debit(address(tok0),b)+ 	lp.debit(address(tok0),s));
		console.log(" 4)  lp.XR[T]=%d",lp.XR(address(tok0)));

		uint snapshot = vm.snapshotState();	

		// - Two consecutive redeems by A:
		//   - First redeem(1, tok0): amount_rdm = floor(1,771,228/1e6) = 1. New state: reserves=1, sum_credits=1000; XR = floor((1+1771)*1e6/1000)=1,772,000.
		//   - Second redeem(1, tok0): amount_rdm = floor(1,772,000/1e6) = 1. New state: reserves=0, sum_credits=999. Total received by A: 2 tok0. Both calls succeed; A has no debt so collateralization checks pass.

		vm.prank(address(a));
		lp.redeem(1, address(tok0));
		vm.prank(address(a));
		lp.redeem(1, address(tok0));
		// Does not revert

		vm.revertToState(snapshot);	

		// - Single redeem attempt:
		//   - redeem(2, tok0) from the state before the two calls (reserves=2, XR=1,771,228) requires amount_rdm = floor(2*1,771,228/1e6) = 3, but reserves=2, so it reverts with """"Redeem: insufficient reserves.""""

		vm.expectRevert();
		vm.prank(address(a));
		lp.redeem(2, address(tok0));
		// This reverts
    }

}
