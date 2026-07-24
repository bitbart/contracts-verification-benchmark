// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {AMM} from "../src/AMM_v1.sol";
import {ERC20} from "../src/lib/ERC20.sol";

contract AMMTest is Test {
    AMM public amm;
    ERC20 public tok0;
    ERC20 public tok1;
    
    function setUp() public {
		tok0 = new ERC20(2000);
		tok1 = new ERC20(2000);
        amm = new AMM(tok0,tok1);
    }
       
    // reserves-gt-zero:

    // PoC produced by GPT-5:

    function test_reserves_gt_zero(address a, address b) public {
		
		vm.assume(a != address(0) && a != address(amm) && a != address(this));
		vm.assume(b != address(0) && b != address(amm) && b != address(this));
		vm.assume(b != a);
		
		tok0.transfer(a, 1000);
		tok1.transfer(a, 1000);	
	
		// Alice: deposit(1000,tok0,1000,tok1)
		vm.prank(address(a));
		tok0.approve(address(amm), 1000);	
		vm.prank(address(a));
		tok1.approve(address(amm), 1000);	
		vm.prank(address(a));
		amm.deposit(1000, 1000);
		
		uint r0 = amm.r0();
		assertGt(r0, 0);
	
    }
    
}
