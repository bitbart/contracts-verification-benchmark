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

    // dep-additivity: if a sender A can perform two (non-reverting) `deposit` of n1 and n2 token units
    // (of the same token T), then A can always obtain an equivalent effect (on the state of the
    // contract and on its own token balance) through a single `deposit` of n1+n2 units of token T.
    // Here equivalence neglects transaction fees.
    // Assume that T is a standard ERC20 token that do not charge fees on transfers.

    // PoC produced by GPT5:
    // - Token T = tok0. Start from empty.
    // - User B:
    // 1) deposit(2, T): XR=1e6 (credits=0 pre), mints 2 credits, reserves[T]=2, sum_credits[T]=2.
    // 2) redeem(1, T): XR=1e6, amount_rdm=(1*1e6/1e6)-1=0. Reserves stay 2, credits decrease to 1 (sum_credits[T]=1). Now XR(T)=(res+deb)*1e6/credits=(2+0)*1e6/1=2e6.
    // - Now consider two options for user A from this state (reserves=2, sum_credits=1, XR=2e6):
    // - Two deposits:
    // a) deposit(1, T): XR=2e6, amount_credit=floor(1e6/2e6)=0; reserves=3, sum_credits=1.
    // b) deposit(1, T): XR=3e6 now, amount_credit=0; reserves=4, sum_credits=1. A’s credits in T: 0.
    // - Single deposit:
    // a) deposit(2, T): XR=2e6, amount_credit=floor(2e6/2e6)=1; reserves=4, sum_credits=2. A’s credits in T: 1.
    // States differ (sum_credits and credit[A][T] differ), while A’s token balance change is the same (-2). Hence the property does not hold.

    function test_dep_additivity(address a, address b) public {
		assert(tok0.totalSupply() == 1000);
		assert(tok0.balanceOf(address(this)) == 1000);

		vm.assume(a != address(0));
		vm.assume(b != address(0));
		vm.assume(a != b);

		tok0.transfer(a, 100);
		tok0.transfer(b, 100);

		// Bob: deposit(2,tok0)	
		vm.prank(address(b));
		tok0.approve(address(lp), 2);	
		vm.prank(address(b));
		lp.deposit(2, address(tok0));

		// Bob: redeem(1,T0)
		vm.prank(address(b));
		lp.redeem(1, address(tok0));

		uint snapshot = vm.snapshotState();	

		vm.prank(address(a));
		tok0.approve(address(lp), 2);	

		// Alice: deposit(1,tok0)	
		vm.prank(address(a));
		lp.deposit(1, address(tok0));

		// Alice: deposit(1,tok0)	
		vm.prank(address(a));
		lp.deposit(1, address(tok0));

		uint credits_a_trace1 = lp.credit(address(tok0),a);
		assertEq(credits_a_trace1, 0);

		vm.revertToState(snapshot);	

		vm.prank(address(a));
		tok0.approve(address(lp), 2);

		// Alice: deposit(2,tok0)
		vm.prank(address(a));
		lp.deposit(2, address(tok0));

		uint credits_a_trace2 = lp.credit(address(tok0),a);

		assertEq(credits_a_trace2, 1);
    }

}
