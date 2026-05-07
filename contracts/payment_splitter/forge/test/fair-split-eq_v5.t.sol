// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v5.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // fair-split-eq: 
    // for every address `a` in `payees`, 
    // `released[a] + releasable(a) == (totalReceived * shares[a]) / totalShares`

    // PoC produced by GPT-5:
    // Deploy with two payees A and B, shares [1, 1] (totalShares = 2). 
    // Send 100 wei to the contract. 
    // For A:
    // - totalReceived = 100
    // - shares[A] / totalShares = 1/2 = 0 (integer division)
    //- releasable(A) = 100 * 0 - 0 = 0; released[A] = 0
    // Left-hand side: released[A] + releasable(A) = 0
    // Right-hand side: (totalReceived * shares[A]) / totalShares = (100 * 1) / 2 = 50
    // Thus 0 != 50, violating the property.

    function test_fair_split_eq(address a, address b) public {
        vm.assume(a != address(0) && a != address(this));
        vm.assume(b != address(0) && b != address(this));
        vm.assume(a != b);

        address[] memory payees = new address[](2);        
        payees[0] = address(a);
        payees[1] = address(b);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 1;
        
        ps = new PaymentSplitter(payees, shares);

        // A sends 100 wei to the contract
        vm.deal(address(a), 100);
        vm.prank(a);
        (bool success,) = address(ps).call{value:100}("");
        assert(success);

        uint totalReceived = address(ps).balance + ps.getTotalReleased();
        assertEq(totalReceived, 100);

        uint released_a = ps.getReleased(a);
        assertEq(released_a, 0);

        uint releasable_a = ps.releasable(a);
        assertEq(releasable_a, 0);

        // lhs = released[a] + releasable(a) 
        uint lhs = released_a + releasable_a;
        assertEq(lhs, 0);

        // rhs = (totalReceived * shares[a]) / totalShares
        uint rhs = (totalReceived * ps.getShares(a)) / ps.getTotalShares();
        assertEq(rhs, 50);

        // violation: lhs != rhs
    }
}
