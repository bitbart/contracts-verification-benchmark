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

    // dep-additivity: if a sender A can perform two (non-reverting) `deposit` of n1 and n2 token units
    // (of the same token T), then A can always obtain an equivalent effect (on the state of the
    // contract and on its own token balance) through a single `deposit` of n1+n2 units of token T.
    // Here equivalence neglects transaction fees.
    // Assume that T is a standard ERC20 token that do not charge fees on transfers.

    // PoC produced by GPT5:
	// Consider token T = tok0. Initial state: sum_credits[T] = 0, sum_debits[T] = 0, reserves[T] = 100 (e.g., someone directly transferred 100 T to the contract). User A has sufficient T and allowance.
	// - Two-step:
	//   1) deposit(50, T): XR = 1e6 (XR_def with credits==0). Minted credits = 50*1e6/1e6 = 50. New state: reserves=150, sum_credits=50.
	//   2) deposit(50, T): XR = (150+0)*1e6/50 = 3,000,000. Minted credits = 50*1e6/3,000,000 = 16 (integer division). Final: reserves=200, sum_credits=66, credit[T][A]=66.
	// - Single-step:
	//   deposit(100, T): XR = 1e6. Minted credits = 100*1e6/1e6 = 100. Final: reserves=200, sum_credits=100, credit[T][A]=100.
	// Both options reduce A’s token balance by 100, but the contract state (sum_credits, credit[T][A]) differs, so the effects are not equivalent.

    function test_dep_additivity() public {
		assert(tok0.totalSupply() == 1000);
		assert(tok0.balanceOf(address(this)) == 1000);

        address a = address(0x111);
        address b = address(0x222);

		tok0.transfer(a, 100);
		tok0.transfer(b, 100);

		// someone directly transferred 100 T to the contract
		vm.prank(address(b));		
		tok0.transfer(address(this), 100);

		uint credits_a_state0 = lp.credit(address(tok0),a);
		assertEq(credits_a_state0, 0);

		uint credits_b_state0 = lp.credit(address(tok0),b);
		assertEq(credits_b_state0, 0);

		uint debts_a_state0 = lp.debit(address(tok0),a);
		assertEq(debts_a_state0, 0);

		uint debts_b_state0 = lp.debit(address(tok0),b);
		assertEq(debts_b_state0, 0);


		uint snapshot = vm.snapshotState();	

		// Alice: deposit(50 tok0)	
		vm.prank(address(a));
		tok0.approve(address(lp), 50);	
		vm.prank(address(a));
		lp.deposit(50, address(tok0));

		// Alice: deposit(50,tok0)	
		vm.prank(address(a));
		tok0.approve(address(lp), 50);	
		vm.prank(address(a));
		lp.deposit(50, address(tok0));

		uint credits_a_trace1 = lp.credit(address(tok0),a);

        console.log("The value of credits_a_trace1 is %d", credits_a_trace1);
		//assertEq(credits_a_trace1, 66);
		// Already here the PoC fails

		vm.revertToState(snapshot);	


		vm.prank(address(a));
		tok0.approve(address(lp), 100);	

		// Alice: deposit(100,tok0)	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));

		uint credits_a_trace2 = lp.credit(address(tok0),a);
		assertNotEq(credits_a_trace1, credits_a_trace2);
    }

}
