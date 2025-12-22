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
       
    // bor-state: if a user A performs a non-reverting `borrow(amount,T)`, then after the transaction:
    // (1) the reserves of T in the `LendingProtocol` are decreased by `amt`;
    // the debits of A in T are increased by `amt`;
    // (3) the debits of A in all tokens different from T are preserved;
    // (4) the credits of A in all tokens are preserved.
    // Assume that T is a standard ERC20 token that do not charge fees on transfers
    
    // PoC produced by GPT-5:
    //- Setup: Some LP deposits 1,000 tok0 to create reserves. User A deposits sufficient collateral (e.g., 1,000 tok1).
    // - Step 1 (at block B): A calls borrow(100, tok0). After this, debit[tok0][A] = 100 and borrow_index[tok0][A] = 1e6; global_borrow_index = 1e6; last_global_update = B.
    // - Step 2: Advance blocks so block.number = B + 1,000,000. This implies a 10% interest period (ratePerPeriod=100,000, blockPeriod=1,000,000).
    // - Step 3: A calls borrow(100, tok0) again. updateBorrowIndex increases global_borrow_index to 1,100,000. _get_accrued_debt returns 110 (100 * 1,100,000 / 1,000,000). The function sets debit[tok0][A] = 110 + 100 = 210. 
    // Result: Reserves[tok0] decreased by 100 as expected, but A’s debit in tok0 increased from 100 to 210 (increase of 110 ≠ amount=100), violating the property. Debits in other tokens and all credits remain unchanged.

    function test_bor_state(address a, address b) public {
		vm.roll(10_000_000);
		assertEq(block.number, 10_000_000);
		
		vm.assume(a != address(0) && a != address(lp) && a != address(this));
		vm.assume(b != address(0) && b != address(lp) && b != address(this));
		vm.assume(b != a);
		
		tok0.transfer(a, 100);
		tok1.transfer(a, 1000);	
		tok0.transfer(b, 1000);
	
		// Bob: deposit(1000,tok0)	
		vm.prank(address(b));
		tok0.approve(address(lp), 1000);
		vm.prank(address(b));
		lp.deposit(1000, address(tok0));
	
		// Alice: deposit(1000,tok1)
		vm.prank(address(a));
		tok1.approve(address(lp), 1000);	
		vm.prank(address(a));
		lp.deposit(1000, address(tok1));
		
		// Alice: deposit(100,tok0)
		vm.prank(address(a));
		tok0.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));	
	
		
		// Alice: borrow(100,tok0)	
		vm.prank(address(a));
		lp.borrow(100, address(tok0));
	
		uint debit0_a_before = lp.debit(address(tok0),a);
		assertEq(tok0.balanceOf(a), 100);
		assertEq(debit0_a_before, 100);
	
		uint accrued_debit0_a_before = lp.getAccruedDebt(address(tok0),a);
		assertEq(accrued_debit0_a_before, 100);
		
		vm.roll(11_000_000);
		assertEq(block.number, 11_000_000);
		// lp.accrueInt();
		
		// Alice: borrow(100,tok0)	
		vm.prank(address(a));
		lp.borrow(100, address(tok0));
	
		// A's debit in tok0 increased from 100 to 210 (increase of 110 != amount=100)	
		uint accrued_debit0_a_after = lp.getAccruedDebt(address(tok0),a);
		assertEq(accrued_debit0_a_after, accrued_debit0_a_before + 110);
    }
    
}
