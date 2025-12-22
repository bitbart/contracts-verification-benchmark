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
		tok0 = new ERC20(1200);
		tok1 = new ERC20(1000);
        lp = new LendingProtocol(tok0,tok1);
    }

    // dep-additivity: if a sender A can perform two (non-reverting) `deposit` of n1 and n2 token units
    // (of the same token T), then A can always obtain an equivalent effect (on the state of the
    // contract and on its own token balance) through a single `deposit` of n1+n2 units of token T.
    // Here equivalence neglects transaction fees.
    // Assume that T is a standard ERC20 token that do not charge fees on transfers.

    // PoC produced by GPT5:
    //- Setup:
    //- User B deposits 1000 tok0: reserves[tok0]=1000, sum_credits[tok0]=1000, XR=1,000,000.
    //- User C borrows 500 tok0: reserves[tok0]=500, sum_debits[tok0]=500, borrowers=[C], XR remains 1,000,000.
    //- Two deposits by A (both succeed):
    //  1) A deposits n1=100 tok0 with XR=1,000,000 ⇒ credit[A]+=100; reserves[tok0]=600; sum_credits[tok0]=1100.
    //  2) Owner calls accrueInt(): C’s debt increases by 10% ⇒ sum_debits[tok0]=550; XR becomes floor((600+550)*1e6/1100)=1,045,454.
    //  3) A deposits n2=100 tok0 with XR=1,045,454 ⇒ credit[A]+=floor(100*1e6/1,045,454)=95.
    // Total credit to A: 195; reserves[tok0]=700.
    // - Single deposit alternatives:
    //  - If A deposits 200 before accrueInt (XR=1,000,000): credit[A]+=200 (≠195).
    //  - If A deposits 200 after accrueInt (XR=1,045,454): credit[A]+=floor(200*1e6/1,045,454)=191 (≠195).
    // In both single-deposit timings, A’s final credit and sum_credits differ from the two-deposit path, so the effects on contract state are not equivalent, even though A’s token balance decreases by 200 in all cases.
			      
    function test_dep_additivity(address a, address b, address c) public {
		// assert(tok0.totalSupply() == 1200);
		// assert(tok0.balanceOf(address(this)) == 1200);

		vm.assume(a != address(0) && a != address(lp));
		vm.assume(b != address(0) && b != a && b != address(lp));
		vm.assume(c != address(0) && c != a && c != b && c != address(lp));

		tok0.transfer(a, 200);
		tok0.transfer(b, 1000);
		tok1.transfer(c, 1000);

		// Bob: deposit(1000,tok0)	
		vm.prank(address(b));
		tok0.approve(address(lp), 1000);	
		vm.prank(address(b));
		lp.deposit(1000, address(tok0));

		// Carol: deposit(1000,tok1)	
		vm.prank(address(c));
		tok1.approve(address(lp), 1000);	
		vm.prank(address(c));
		lp.deposit(1000, address(tok1));

		// Carol: borrow(500,T0)
		vm.prank(address(c));
		lp.borrow(500, address(tok0));

		vm.prank(address(a));
		tok0.approve(address(lp), 200);	

		uint snapshot = vm.snapshotState();	

		// Alice: deposit(100,tok0)	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));

		// accrueInt
		lp.accrueInt();

		// Alice: deposit(100,tok0)	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));

		uint credits_a_trace1 = lp.credit(address(tok0),a);
		assertEq(credits_a_trace1, 195);

		vm.revertToState(snapshot);	

		// Alice: deposit(200,tok0)	
		vm.prank(address(a));
		lp.deposit(200, address(tok0));

		uint credits_a_trace2 = lp.credit(address(tok0),a);
		assertEq(credits_a_trace2, 200);	
    }
}
