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

    // rdm_tokens: if a user A performs a non-reverting `redeem(amount,T)`, then after the transaction:
    // (1) the T balance of the `LendingProtocol` is decreased by `amt * XR(T) / 1e6`;
    // (2) the T balance of A is increased by `amt * XR(T) / 1e6`.
    // Assume that XR(T) in is that in the pre-state, and that
    // T is a standard ERC20 token that do not charge fees on transfers.
    
    // PoC produced by GPT5:
    // Let A deposit 100 T when XR(T)=1e6 (initial state with no credits makes XR=1e6).
    // A then calls redeem(100, T). Pre-state XR=1e6, so amount_rdm = (100*1e6)/1e6 - 1 = 99.
    // The protocol’s T balance decreases by 99 and A’s T balance increases by 99,
    // not by 100 as the property claims.

    function test_rdm_tokens(address a, address b) public {
		assert(tok0.totalSupply() == 1000);
		assert(tok0.balanceOf(address(this)) == 1000);

		vm.assume(a != address(0) && a != address(this) && a != address(lp));
		vm.assume(b != address(0) && b != address(this) && b != address(lp));
		vm.assume(a != b);

		tok0.transfer(a, 100);
		tok0.transfer(b, 900);

		// Alice: deposit(100,T0)	
		vm.prank(address(a));
		tok0.approve(address(lp), 100);	
		vm.prank(address(a));
		lp.deposit(100, address(tok0));

		uint balance0_a_before = tok0.balanceOf(a);
		assertEq(balance0_a_before, 0);

		// Alice: redeem(100,T0)
		vm.prank(address(a));
		lp.redeem(100, address(tok0));

		// (2) is violated: the balance of A in T0 is NOT increased by 100 (but by 99);	
		uint balance0_a_after = tok0.balanceOf(a);
		assertEq(balance0_a_after, 99);
    }
}
