// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v2.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // releasable-sum-balance: 
    // the sum of the releasable funds for every addresses is equal to the balance of the contract.

    // PoC produced by GPT-5:
    // - Deploy with payees A, B, C and shares 1, 1, 1 (constructor).
    // - Send 1 wei to the contract (receive()).
    // - totalShares = 3, totalReleased = 0, balance = 1.
    // - For each payee X ∈ {A,B,C}: releasable(X) = floor((1 * 1)/3) - 0 = 0.
    // - Sum of releasable = 0, while contract balance = 1. Property violated.

    function test_releasable_leq_balance() public {

        address a = address(0x1);
        address b = address(0x2);
        address c = address(0x3);

        vm.prank(a);
        ps = new PaymentSplitter(a,1,b,1,c,1);

        // A sends 1 wei to the contract
        vm.deal(address(a), 1);
        vm.prank(a);
        (bool success1,) = address(ps).call{value:1}("");
        assert(success1);

        uint releasable_a = ps.releasable(a);
        uint releasable_b = ps.releasable(b);
        uint releasable_c = ps.releasable(c);
        assertEq(releasable_a + releasable_b + releasable_c, 0);
        assertEq(address(ps).balance, 1);
    }
}
