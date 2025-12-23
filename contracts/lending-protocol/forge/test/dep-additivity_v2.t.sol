// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LendingProtocol} from "../src/LendingProtocol_v3.sol";
import {ERC20} from "../src/lib/ERC20.sol";
import {console} from "forge-std/console.sol";

contract LPTest is Test {
    LendingProtocol public lp;
    ERC20 public tok0;
    ERC20 public tok1;
    
    function setUp() public {
		tok0 = new ERC20(1000);
		tok1 = new ERC20(1000);
        lp = new LendingProtocol(tok0,tok1);
    }

	// "- Setup (token T = tok0):
	//  1) User B: deposit 100 T. Now reserves[T]=100, sum_credits[T]=100, XR(T)=1e6.
	//  2) User L: deposit 100 tok1 as collateral, then borrow 50 T. Now reserves[T]=50, sum_debits[T]=50; last_global_update set.
	//  3) Wait some blocks so XR reflects interest (without calling borrow/repay). Suppose XR(T) = (reserves + updated_debt) * 1e6 / sum_credits = (50 + 55) * 1e6 / 100 = 1,050,000.
	// - Two deposits by A in the same block:
	//  - First: deposit(1, T): amount_credit = floor(1,000,000 / 1,050,000) = 0. State: reserves+=1; credits[A]+=0; sum_credits unchanged.
	//  - Second: deposit(1, T): XR is ≥ previous; amount_credit = 0 again. End: reserves increased by 2; credits[A] increased by 0; sum_credits unchanged.
	// - Single deposit alternative:
	//  - deposit(2, T) at that time: amount_credit = floor(2,000,000 / 1,050,000) = 1. End: reserves increased by 2; credits[A] increased by 1; sum_credits increased by 1.
	// States differ (credit[A] and sum_credits), while A’s token outflow is the same (2 T). Hence the property is false.
	// "

    function test_dep_additivity(uint256 blocknum1_input, uint256 blocknum2_input) public {
		assert(tok0.totalSupply() == 1000);
		assert(tok0.balanceOf(address(this)) == 1000);
		assert(tok1.totalSupply() == 1000);
		assert(tok1.balanceOf(address(this)) == 1000);
		vm.assume(blocknum2_input > blocknum1_input);


        address a = address(0x111);
        address b = address(0x222);
        address l = address(0x333);

		uint256 my_blocknum1 = blocknum1_input;
		uint256 my_blocknum2 = blocknum2_input;

		tok0.transfer(a, 100);
		tok0.transfer(b, 100);
		tok1.transfer(l, 100);

		// We are in block n1
	    vm.roll(my_blocknum1);
        console.log("The value of the blocknum 1 is %d", vm.getBlockNumber());

		//  1) User B: deposit 100 T. Now reserves[T]=100, sum_credits[T]=100, XR(T)=1e6.
		// Bob: deposit(100 tok0)	
		vm.prank(address(b));
		tok0.approve(address(lp), 100);	
		vm.prank(address(b));
		lp.deposit(100, address(tok0));

		console.log(" 1)  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" 1)  sum_credits[T]=%d",lp.credit(address(tok0),a)+lp.credit(address(tok0),b)+ 	lp.credit(address(tok0),l));
		console.log(" 1)  sum_debits[T]=%d",lp.debit(address(tok0),a)+lp.debit(address(tok0),b)+ 	lp.debit(address(tok0),l));
		console.log(" 1)  lp.XR[T]=%d",lp.XR(address(tok0)));

		//  2) User L: deposit 100 tok1 as collateral, then borrow 50 T. Now reserves[T]=50, sum_debits[T]=50; last_global_update set.

		// Leo: deposit(100 tok1)	
		vm.prank(address(l));
		tok1.approve(address(lp), 100);	
		vm.prank(address(l));
		lp.deposit(100, address(tok1));


		// Leo: borrow(50 tok0)	
		vm.prank(address(l));
		lp.borrow(50, address(tok0));
		uint256 new_XR = lp.XR(address(tok0));

		console.log(" 2)  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" 2)  sum_credits[T]=%d",lp.credit(address(tok0),a)+lp.credit(address(tok0),b)+ 	lp.credit(address(tok0),l));
		console.log(" 2)  sum_debits[T]=%d",lp.getUpdatedSumDebits(address(tok0)));
		console.log(" 2)  lp.XR[T]=%d",lp.XR(address(tok0)));
	
		//  3) Wait some blocks so XR reflects interest (without calling borrow/repay). Suppose XR(T) = (reserves + updated_debt) * 1e6 / sum_credits = (50 + 55) * 1e6 / 100 = 1,050,000.

		uint256 sum_debit_block1 = lp.debit(address(tok0),a)+lp.debit(address(tok0),b)+ 	lp.debit(address(tok0),l);
		// We are now in block n2
	    vm.roll(my_blocknum2);

		uint256 sum_debit_block2 = lp.debit(address(tok0),a)+lp.debit(address(tok0),b)+ 	lp.debit(address(tok0),l);


        console.log("The value of the blocknum 2 is %d", vm.getBlockNumber());

		console.log(" 3)  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" 3)  sum_credits[T]=%d",lp.credit(address(tok0),a)+lp.credit(address(tok0),b)+ 	lp.credit(address(tok0),l));
		console.log(" 3)  sum_debits[T]=%d",lp.getUpdatedSumDebits(address(tok0)));
		console.log(" 3)  lp.XR[T]=%d",lp.XR(address(tok0)));

		assertEq(lp.XR(address(tok0)), 1000000);	// This seems to always hold ... ?


		uint snapshot = vm.snapshotState();	

		vm.prank(address(a));
		tok0.approve(address(lp), 2);	

		// Alice: deposit(1,tok0)	
		vm.prank(address(a));
		lp.deposit(1, address(tok0));

		console.log(" 4 step1)  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" 4 step1)  sum_credits[T]=%d",lp.credit(address(tok0),a)+lp.credit(address(tok0),b)+ 	lp.credit(address(tok0),l));
		console.log(" 4 step1)  sum_debits[T]=%d",lp.getUpdatedSumDebits(address(tok0)));
		console.log(" 4 step1)  lp.XR[T]=%d",lp.XR(address(tok0)));

		// Alice: deposit(1,tok0)	
		vm.prank(address(a));
		lp.deposit(1, address(tok0));

		console.log(" 4 step2)  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" 4 step2)  sum_credits[T]=%d",lp.credit(address(tok0),a)+lp.credit(address(tok0),b)+ 	lp.credit(address(tok0),l));
		console.log(" 4 step2)  sum_debits[T]=%d",lp.getUpdatedSumDebits(address(tok0)));
		console.log(" 4 step2)  lp.XR[T]=%d",lp.XR(address(tok0)));

		uint credits_a_trace1 = lp.credit(address(tok0),a);

		vm.revertToState(snapshot);	
		console.log(" ... Reverting to snapshot...");

		vm.prank(address(a));
		tok0.approve(address(lp), 2);

		// Alice: deposit(2,tok0)
		vm.prank(address(a));
		lp.deposit(2, address(tok0));

		console.log(" 4 from reverted  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" 4 from reverted   sum_debits[T]=%d",lp.getUpdatedSumDebits(address(tok0)));
		console.log(" 4 from reverted   lp.XR[T]=%d",lp.XR(address(tok0)));

		uint credits_a_trace2 = lp.credit(address(tok0),a);

		assertNotEq(credits_a_trace2, credits_a_trace1);
    }

}
