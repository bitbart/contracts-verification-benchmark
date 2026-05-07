// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v5.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // fair-split-no-overflow: for every address `a` in `payees`, 
    // `released[a] + releasable(a) == (totalReceived * shares[a]) / totalShares` 
    // whenever the expression does not overflow.

    // PoC produced by GPT-5:
    // Deploy with payees = [A, B], shares = [1, 99].
    // - Send 100 wei to the contract.
    // - totalReceived = address(this).balance + totalReleased = 100 + 0 = 100.
    // - For A: shares[A] = 1, totalShares = 100.
    // - Contract computes: releasable(A) = 100 * (1/100) - 0 = 0 (since 1/100 = 0 by integer division). So released[A] + releasable(A) = 0.
    // - Property RHS: (100 * 1) / 100 = 1.
    // - Hence 0 != 1, violating the property without overflow.

    function test_fair_split_eq_no_overflow(address a, address b) public {
        vm.assume(a != address(0) && a != address(this));
        vm.assume(b != address(0) && b != address(this));
        vm.assume(a != b);

        address[] memory payees = new address[](2);        
        payees[0] = address(a);
        payees[1] = address(b);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 99;
        
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
        assertEq(rhs, 1);

        // violation: lhs != rhs
    }
}
