// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v9.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // fair-split-eq: 
    // for every address `a` in `payees`, 
    // `released[a] + releasable(a) == (totalReceived * shares[a]) / totalShares`

    // PoC produced by GPT-5:
    // - Deploy with payees [owner, Bob], shares [1, 1].
    // - Send 2 wei to the contract.
    // - Call release(Bob): payment = (2*1)/2 - 0 = 1; after: released[Bob] = 1, totalReleased = 1, balance = 1.
    // - Call release(Charlie) where Charlie has 0 shares (not a payee): payment = 0, so the else branch sends 1 wei to owner; after: balance = 0, totalReleased = 1.
    // - Now for a = Bob: RHS = ((balance + totalReleased) * shares[a]) / totalShares = (0 + 1) * 1 / 2 = 0, 
    //   but released[Bob] = 1. releasable(Bob) would be (1*1)/2 - 1 = 0 - 1, which underflows and reverts. 
    // Hence released[Bob] + releasable(Bob) ≠ 0, violating the property.

    function test_fair_split_eq() public {

        address o = address(0x1);
        address b = address(0x2);
        address c = address(0x3);

        address[] memory payees = new address[](2);        
        payees[0] = address(o);
        payees[1] = address(b);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 1;

        vm.prank(o);        
        ps = new PaymentSplitter(payees, shares);

        // C sends 100 wei to the contract
        vm.deal(address(c), 2);
        vm.prank(c);
        (bool success,) = address(ps).call{value:2}("");
        assert(success);

        ps.release(payable(b));
        ps.release(payable(c));

        // rhs = (totalReceived * shares[b]) / totalShares
        uint totalReceived = address(ps).balance + ps.getTotalReleased();
        uint rhs = (totalReceived * ps.getShares(b)) / ps.getTotalShares();
        assertEq(rhs, 0);

        // lhs = released[b] + releasable(b) 
        vm.expectRevert();
        uint releasable_b = ps.releasable(b);

        // violation: lhs (reverted) != rhs
    }
}
