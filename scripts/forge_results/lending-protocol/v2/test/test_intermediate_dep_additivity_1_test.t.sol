pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
//import {LendingProtocol} from "../src/LendingProtocol.sol";
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


    function test_dep_additivity() public {
		assert(tok0.totalSupply() == 1000);
		assert(tok0.balanceOf(address(this)) == 1000);
		assert(tok1.totalSupply() == 1000);
		assert(tok1.balanceOf(address(this)) == 1000);


        address a = address(0x111);
        address b = address(0x222);
        address l = address(0x333);

		uint256 my_blocknum1 = 1;
		uint256 my_blocknum2 = 200001;

		assertGt(my_blocknum2, my_blocknum1);

		tok0.transfer(a, 100);
		tok0.transfer(b, 100);
		tok1.transfer(l, 100);

		// We are in block n1
	    vm.roll(my_blocknum1);

		//  1) User B: deposit 100 T. Now reserves[T]=100, sum_credits[T]=100, XR(T)=1e6.
		// Bob: deposit(100 tok0)	
		vm.prank(address(b));
		tok0.approve(address(lp), 100);	
		vm.prank(address(b));
		lp.deposit(100, address(tok0));


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

	
		//  3) Wait some blocks so XR reflects interest (without calling borrow/repay). Suppose XR(T) = (reserves + updated_debt) * 1e6 / sum_credits = (50 + 55) * 1e6 / 100 = 1,050,000.
	    	vm.roll(my_blocknum2);


		assertNotEq(lp.XR(address(tok0)), 1000000);

    }

}