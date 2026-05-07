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

    // PoC produced by GPT-5:
    // - Setup: Deploy with payees [owner (msg.sender), Bob] and shares [1, 1]. totalShares = 2.
    // - Fund: Send 2 wei to the contract.
    // - Step 1: Call release(Bob). Payment = ( (2) * 1 ) / 2 - 0 = 1 wei. After execution: released[Bob] = 1, totalReleased = 1, contract balance = 1.
    // - Step 2: Call release(Bob) again. Now payment = ( (balance + totalReleased) * 1 ) / 2 - released[Bob] = ( (1 + 1) * 1 ) / 2 - 1 = 0, so the else branch executes and sends 1 wei to owner. 
    // After this: contract balance = 0, totalReleased = 1 (unchanged), totalReceived = balance + totalReleased = 1.
    // - Check: Bob’s entitlement = (1 * 1) / 2 = 0, but released[Bob] = 1. 
    // Thus (totalReceived * shares[Bob]) / totalShares < released[Bob], violating the property.

    function test_fair_split_geq() public {
        address o = address(0x1);
        address a = address(0x2);
        address b = address(0x3);

        address[] memory payees = new address[](2);        
        payees[0] = address(o);
        payees[1] = address(b);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 1;

        vm.prank(o);
        ps = new PaymentSplitter(payees, shares);

        // A sends 2 wei to the contract
        vm.deal(address(a), 2);
        vm.prank(a);
        (bool success1,) = address(ps).call{value:2}("");
        assert(success1);

        ps.release(payable(b));
        ps.release(payable(b));

        // rhs = (totalReceived * shares[b]) / totalShares
        uint totalReceived = address(ps).balance + ps.getTotalReleased();
        uint rhs = (totalReceived * ps.getShares(b)) / ps.getTotalShares();
        assertEq(rhs, 0);

        // lhs = released[b] + releasable(b) 
        uint released_b = ps.getReleased(b);
        assertEq(released_b, 1);
        
        vm.expectRevert();
        uint releasable_b = ps.releasable(b);

        // violation: lhs (reverted) != rhs
    }
}
