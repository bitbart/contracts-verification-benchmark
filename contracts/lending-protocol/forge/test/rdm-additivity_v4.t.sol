// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {LendingProtocol} from "../src/LendingProtocol_v4.sol";
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

		// - Tokens: use tok0 as the redeemed token T (price 1) and tok1 as the borrowed token (price 2). tLiq = 666,666.
		// - Setup:
		//   1) Some other user deposits >= 200,000,000 tok1 so reserves[tok1] are sufficient.
		//   2) A deposits 600 tok0: after deposit, reserves[tok0]=600, sum_credits[tok0]=600, credit[tok0][A]=600, XR(tok0)=1,000,000.
		//   3) A borrows 133,800,000 tok1 (reserves[tok1] sufficient). Collateral holds since hf ≈ (600,000,000*666,666)/(133,800,000*2) > 1,000,000.
		// - Two consecutive redeems on tok0:
		//   4) A calls redeem(100, tok0): XR pre = 1,000,000, amount_rdm1 = 100 - 1 = 99; post: reserves[tok0]=501, sum_credits=500. New XR = floor(501e6/500)=1,002,000. Collateral: valCredit=500*1,002,000=501,000,000; hf ≈ (501,000,000*666,666)/(267,600,000) > 1,000,000.
		//   5) A calls redeem(100, tok0): XR pre = 1,002,000, amount_rdm2 = floor(100*1,002,000/1e6) - 1 = 100 - 1 = 99; post: reserves[tok0]=402, sum_credits=400. New XR = floor(402e6/400)=1,005,000. Collateral: valCredit=400*1,005,000=402,000,000; hf ≈ (402,000,000*666,666)/(267,600,000) ≈ 1,001,493 > 1,000,000. Both redeems succeed.
		// - Single redeem attempt:
		//   From the state after step (3), try redeem(200, tok0). XR pre = 1,000,000, amount_rdm = 200 - 1 = 199; post: reserves[tok0]=401, sum_credits=400, XR = floor(401e6/400)=1,002,500. Collateral: valCredit=400*1,002,500=401,000,000; hf ≈ (401,000,000*666,666)/(267,600,000) < 1,000,000, so the redeem reverts at require(_isCollateralized(msg.sender)).
		// Thus, A can perform two consecutive successful redeems of 100 and 100, but cannot “obtain an equivalent effect” via a single redeem of 200 (it fails), violating the stated property.
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

		//   1) Some other user deposits >= 200,000,000 tok1 so reserves[tok1] are sufficient.

		vm.prank(address(b));
		tok1.approve(address(lp), 200000000);	
		vm.prank(address(b));
		lp.deposit(200000000, address(tok1));
		
		//   2) A deposits 600 tok0: after deposit, reserves[tok0]=600, sum_credits[tok0]=600, credit[tok0][A]=600, XR(tok0)=1,000,000.

		vm.prank(address(a));
		tok0.approve(address(lp), 600);	
		vm.prank(address(a));
		lp.deposit(600, address(tok0));
		
		//   3) A borrows 133,800,000 tok1 (reserves[tok1] sufficient). Collateral holds since hf ≈ (600,000,000*666,666)/(133,800,000*2) > 1,000,000.

		vm.prank(address(a));
		lp.borrow(133800000, address(tok1));
		
		uint snapshot = vm.snapshotState();	

		// - Two consecutive redeems by A:
		vm.prank(address(a));
		lp.redeem(100, address(tok0));
		vm.prank(address(a));
		lp.redeem(100, address(tok0));
		// Does not revert

		vm.revertToState(snapshot);	

		// - Single redeem attempt:
		vm.expectRevert();
		vm.prank(address(a));
		lp.redeem(200, address(tok0));
		// This reverts
		
    }

}
