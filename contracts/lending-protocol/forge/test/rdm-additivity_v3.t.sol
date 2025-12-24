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
    
    function test_dep_additivity() public {
		tok0 = new ERC20(10000);
		tok1 = new ERC20(10000);
		address owner = address(0x04834);
		vm.prank(owner);
        lp = new LendingProtocol(tok0,tok1);

		// - Token T = tok0. Let the state be:
		//   reserves[T] = 50, sum_credits[T] = 100, sum_debits[T] = 100, and user A has credit[T][A] >= 2. This state is reachable, e.g., A deposits 100 tok0 (R=100, C=100), another user B borrows 50 tok0 (R=50, D=50) with minimal collateral in tok1, and then the owner calls accrueInt repeatedly until D ≈ 100.
		// - Then XR(T) = floor((50 + 100) * 1e6 / 100) = 1,500,000.

		// Two consecutive redeems by A:
		// 1) redeem(1, T): amount_rdm1 = floor(1 * 1,500,000 / 1e6) = 1 → reserves = 49, sum_credits = 99. New XR = floor((49 + 100) * 1e6 / 99) = 1,505,050.
		// 2) redeem(1, T): amount_rdm2 = floor(1 * 1,505,050 / 1e6) = 1 → reserves = 48, sum_credits = 98.
		// Total received by A = 2 tokens.

		// Single redeem by A:
		// - redeem(2, T) from the initial state: amount_rdm = floor(2 * 1,500,000 / 1e6) = 3 → reserves = 47, sum_credits = 98.
		// Total received by A = 3 tokens.

		// Both sequences succeed (A has sufficient credits; reserves suffice; A has no debt so _isCollateralized returns true), yet the outcomes differ. Therefore, the property is violated.

		assert(tok0.totalSupply() == 10000);
		assert(tok0.balanceOf(address(this)) == 10000);
		assert(tok1.totalSupply() == 10000);
		assert(tok1.balanceOf(address(this)) == 10000);


        address a = address(0x111);
        address b = address(0x222);
        address s = address(0x333);

		tok0.transfer(a, 1000);
		tok0.transfer(b, 1000);
		tok0.transfer(s, 1000);
		tok1.transfer(b, 1000);

		
		//A deposits 100 tok0 (R=100, C=100),
		vm.prank(address(a));
		tok0.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));

		// another user B borrows 50 tok0 (R=50, D=50) with minimal collateral in tok1, 
		vm.prank(address(b));
		tok1.approve(address(lp), 1);	
		vm.prank(address(b));
		lp.deposit(1, address(tok1));

		vm.prank(address(b));
		lp.borrow(50, address(tok0));

		//and then the owner calls accrueInt repeatedly until D ≈ 100.
		// - Then XR(T) = floor((50 + 100) * 1e6 / 100) = 1,500,000.
		
		vm.startPrank(address(owner));
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();
		lp.accrueInt();
		vm.stopPrank();
		console.log(" 0)  Now reserves[T]=%d",lp.reserves(address(tok0)));
		console.log(" 0)  sum_credits[T]=%d",lp.credit(address(tok0),a)+lp.credit(address(tok0),b)+ 	lp.credit(address(tok0),s));
		console.log(" 0)  sum_debits[T]=%d",lp.debit(address(tok0),a)+lp.debit(address(tok0),b)+ 	lp.debit(address(tok0),s));
		console.log(" 0)  lp.XR[T]=%d",lp.XR(address(tok0)));


		uint snapshot = vm.snapshotState();	

		// - Two consecutive redeems by A:

		vm.prank(address(a));
		lp.redeem(1, address(tok0));
		vm.prank(address(a));
		lp.redeem(1, address(tok0));
		// Does not revert
		uint256 reserves_path1 = lp.reserves(address(tok0));

		vm.revertToState(snapshot);	

		// - Single redeem attempt:

		vm.prank(address(a));
		lp.redeem(2, address(tok0));
		// Does not revert
		uint256 reserves_path2 = lp.reserves(address(tok0));

		assertNotEq(reserves_path2,reserves_path1);
    }

}
