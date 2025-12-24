// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LendingProtocol} from "../src/LendingProtocol_v7.sol";
import {ERC20} from "../src/lib/ERC20.sol";
import {console} from "forge-std/console.sol";

contract LPTest is Test {
    LendingProtocol public lp;
    ERC20 public tok0;
    ERC20 public tok1;
    
    function test_rdm_additivity() public {
		tok0 = new ERC20(10000000000);
		tok1 = new ERC20(10000000000);
		address owner = address(0x04834);
		vm.prank(owner);
        lp = new LendingProtocol(tok0,tok1);

		// - Token T = tok0. Start from a reachable state:
		//   1) A deposits 100 T: deposit(100, tok0) → reserves=50? No, after this step reserves=100, sum_credits=100, debits=0.
		//   2) B borrows 50 T: borrow(50, tok0) → reserves=50, sum_debits=50, borrowers=[B].
		//   3) Owner calls accrueInt() once (ratePerPeriod = 10%): B’s debit increases by 5 → sum_debits=55. Now XR(T) = ((50+55)*1e6)/100 = 1,050,000.

		// - Two consecutive redeems by A, with no interest accruals in between:
		//   4) redeem(11, tok0):
		//      - xr = 1,050,000
		//      - amount_rdm = (11*1,050,000)/1e6 = 11
		//      - New state: reserves=39, sum_credits=89
		//   5) redeem(9, tok0):
		//      - xr = ((39+55)*1e6)/89 = floor(94e6/89) = 1,056,179
		//      - amount_rdm = (9*1,056,179)/1e6 = 9
		//      - New state: reserves=30, sum_credits=80
		//   - Total T received by A: 11 + 9 = 20

		// - Single redeem from the state after step (3):
		//   - redeem(20, tok0):
		//     - xr = 1,050,000
		//     - amount_rdm = (20*1,050,000)/1e6 = 21
		//     - New state: reserves=29, sum_credits=80

		// - Comparison: Two-step leaves reserves=30 and pays A 20 T; one-step leaves reserves=29 and pays A 21 T. Both sequences satisfy all require checks (including collateralization), and no interest accruals occur between the two redeems in the two-step sequence. Hence, the “equivalent effect” condition fails.
		
		assert(tok0.totalSupply() == 10000000000);
		assert(tok0.balanceOf(address(this)) == 10000000000);
		assert(tok1.totalSupply() == 10000000000);
		assert(tok1.balanceOf(address(this)) == 10000000000);


        address a = address(0x111);
        address b = address(0x222);

		tok0.transfer(a, 200000000);
		tok0.transfer(b, 200000000);
		tok1.transfer(a, 200000000);
		tok1.transfer(b, 200000000);

		//   1) A deposits 100 T: deposit(100, tok0) → reserves=50? No, after this step reserves=100, sum_credits=100, debits=0..
		vm.prank(address(a));
		tok0.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));

		// This is needed to make the PoC pass!! But it misses from gpt5 answer
		// vm.prank(address(b));
		// tok1.approve(address(lp), 1);	
		// vm.prank(address(b));
		// lp.deposit(1, address(tok1));

		//   2) B borrows 50 T: borrow(50, tok0) → reserves=50, sum_debits=50, borrowers=[B]
		vm.prank(address(b));
		lp.borrow(50, address(tok0));

		//   3) Owner calls accrueInt() once (ratePerPeriod = 10%): B’s debit increases by 5 → sum_debits=55. Now XR(T) = ((50+55)*1e6)/100 = 1,050,000.
		vm.prank(address(owner));
		lp.accrueInt();
		
		uint snapshot = vm.snapshotState();	

		// - Two consecutive redeems by A:
		vm.prank(address(a));
		lp.redeem(11, address(tok0));

		console.log(" path1.1)  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" path1.1)  sum_credits[T]=%d",lp.credit(address(tok0),a)+lp.credit(address(tok0),b));
		console.log(" path1.1)  sum_debits[T]=%d",lp.debit(address(tok0),a)+lp.debit(address(tok0),b));
		console.log(" path1.1)  lp.XR[T]=%d",lp.XR(address(tok0)));

		vm.prank(address(a));
		lp.redeem(9, address(tok0));
		// Does not revert
		uint256 reserves_path1 = lp.reserves(address(tok0));
		console.log(" path1.2)  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" path1.2)  sum_credits[T]=%d",lp.credit(address(tok0),a)+lp.credit(address(tok0),b));
		console.log(" path1.2)  sum_debits[T]=%d",lp.debit(address(tok0),a)+lp.debit(address(tok0),b));
		console.log(" path1.2)  lp.XR[T]=%d",lp.XR(address(tok0)));

		vm.revertToState(snapshot);	

		// - Single redeem attempt:
		vm.prank(address(a));
		lp.redeem(20, address(tok0));
		// Does not revert
		uint256 reserves_path2 = lp.reserves(address(tok0));
		console.log(" path2)  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" path2)  sum_credits[T]=%d",lp.credit(address(tok0),a)+lp.credit(address(tok0),b));
		console.log(" path2)  sum_debits[T]=%d",lp.debit(address(tok0),a)+lp.debit(address(tok0),b));
		console.log(" path2)  lp.XR[T]=%d",lp.XR(address(tok0)));
		assertNotEq(reserves_path2,reserves_path1);
    }

}
