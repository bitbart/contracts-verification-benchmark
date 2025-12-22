// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LendingProtocol} from "../src/LendingProtocol_v2.sol";
import {ERC20} from "../src/lib/ERC20.sol";

contract LPTest is Test {
    LendingProtocol public lp;
    ERC20 public tok0;
    ERC20 public tok1;
    
    function setUp() public {
		tok0 = new ERC20(2000);
		tok1 = new ERC20(2000);
        lp = new LendingProtocol(tok0,tok1);
    }

    // - Setup with tok0 as the token under test and tok1 as collateral token; prices are prices[tok0]=1, prices[tok1]=2.
    // 1) LP deposits 3 units of tok0:
    //    - reserves[tok0]=3, sum_credits[tok0]=3, XR(tok0)=1e6.
    // 2) Borrower deposits 1 unit of tok1 (to pass collateral checks).
    // 3) Borrower borrows 2 units of tok0 in block N:
    //    - reserves[tok0]=1, sum_debits[tok0]=2, sum_debits_index[tok0]=1e6, last_global_update=N, global_borrow_index=1e6.
    // 4) Advance 10,000,000 blocks (elapsed = 10 periods). XR(tok0) now uses virtual accrual:
    //    - multiplier = 1e6 + (100,000*10,000,000)/1,000,000 = 2,000,000\n   - _global_borrow_index = 2,000,000
    //    - tot_debt = 2*2,000,000/1,000,000 = 4\n   - XR_pre = ((reserves + tot_debt) * 1e6) / sum_credits = ((1 + 4) * 1e6) / 3 = 1,666,666
    // 5) LP calls deposit(1, tok0):
    //    - amount_credit = (1*1e6)/1,666,666 = 0 (floored)
    //    - Post-state: reserves[tok0]=2, sum_credits[tok0]=3\n   - XR_post = ((2 + 4) * 1e6) / 3 = 2,000,000 Since XR_post ≠ XR_pre, the exchange rate is not preserved by the deposit transaction.
       
    function test_dep_xr_eq(address a, address b) public {
		assert(tok0.totalSupply() == 2000);
		assert(tok0.balanceOf(address(this)) == 2000);
		assert(tok1.totalSupply() == 2000);
		assert(tok1.balanceOf(address(this)) == 2000);
	
		// sets block number to 0
		vm.roll(0);
		
		vm.assume(a != address(0) && a != address(lp) && a != address(this));
		vm.assume(b != address(0) && b != address(lp) && b != address(this));
		vm.assume(b != a);
		
		tok0.transfer(a, 100);
		tok1.transfer(b, 100);
	
		// Alice: deposit(3,tok0)	
		vm.prank(address(a));
		tok0.approve(address(lp), 3);	
		vm.prank(address(a));
		lp.deposit(3, address(tok0));
	
		// Bob: deposit(1,tok1)	
		vm.prank(address(b));
		tok1.approve(address(lp), 1);
		vm.prank(address(b));
		lp.deposit(1, address(tok1));
	
		// Bob: borrow(2,tok0)	
		vm.prank(address(b));
		lp.borrow(2, address(tok0));
	
		assertEq(tok0.balanceOf(b), 2);
	
		vm.roll(10_000_000);
		assertEq(block.number, 10_000_000);	
		// lp.accrueInt();
		
		uint xr0_before = lp.XR(address(tok0));
		assertEq(xr0_before, 1_666_666);
	
		// Alice: deposit(1:tok0)
		vm.prank(address(a));
		tok0.approve(address(lp), 1);	
		vm.prank(address(a));
		lp.deposit(1, address(tok0));
	
		uint xr0_after = lp.XR(address(tok0));
		assert(xr0_after != xr0_before);
		assertEq(lp.XR(address(tok0)), 2_000_000);
    }    
}
