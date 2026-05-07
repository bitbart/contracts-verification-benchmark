// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v8.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // fair-split-geq: 
    // for every address `a` in `payees`, 
    // `released[a] + releasable(a) >= (totalReceived * shares[a]) / totalShares`
    // whenever the expression does not overflow.

    // PoC produced by GPT-5:
    // - Deploy with payees [A, B] and shares [1, 2], where A is the owner (payees_[0] == msg.sender).
    // - Send 2 wei to the contract.
    // - Call release(B): payment = floor((2 * 2) / 3) = 1; released[B] = 1; totalReleased = 1; balance becomes 1; totalReceived stays 2.
    // - Call release(A): payment = floor((2 * 1) / 3) - released[A] = 0 - 0 = 0, so the else branch sends 1 wei to owner. Now balance = 0, totalReleased = 1, released[A] = 0, released[B] = 1, so totalReceived = 0 + 1 = 1.
    // - For B: (totalReceived * shares[B]) / totalShares = floor((1 * 2) / 3) = 0, but released[B] = 1. Thus 0 >= 1 is false, violating the property.

    function test_fair_split_geq_no_overflow() public {
        address a = address(0x1);
        address b = address(0x2);

        address[] memory payees = new address[](2);        
        payees[0] = address(a);
        payees[1] = address(b);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 2;

        vm.prank(a);
        ps = new PaymentSplitter(payees, shares);

        // A sends 2 wei to the contract
        vm.deal(address(a), 2);
        vm.prank(a);
        (bool success1,) = address(ps).call{value:2}("");
        assert(success1);

        ps.release(payable(b));
        ps.release(payable(a));

        // rhs = (totalReceived * shares[b]) / totalShares
        uint totalReceived = address(ps).balance + ps.getTotalReleased();
        assertEq(totalReceived, 1);
        uint rhs = (totalReceived * ps.getShares(b)) / ps.getTotalShares();
        assertEq(rhs, 0);

        // lhs = released[b] + releasable(b) 
        uint released_b = ps.getReleased(b);
        assertEq(released_b, 1);

        // releasable(b) 
        // = (totalReceived * shares[b]) / totalShares - released[b];
        // = (1 * 2) / 3 - 1 = 0 - 1   ===>   underflow
        vm.expectRevert();
        uint releasable_b = ps.releasable(b);

        // violation: lhs (reverted) != rhs
    }
}
