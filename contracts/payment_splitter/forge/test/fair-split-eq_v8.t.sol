// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v8.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // fair-split-eq: 
    // for every address `a` in `payees`, 
    // `released[a] + releasable(a) == (totalReceived * shares[a]) / totalShares`

    // PoC produced by GPT-5:
    // - Deploy with payees [Owner O, Alice A], shares [1, 2] (totalShares = 3).
    // - Send 3 wei to the contract.
    // - Call release(O): pays 1 wei to O.
    // - Call release(A): pays 2 wei to A. Now totalReleased = 3, balance = 0, released[O]=1, released[A]=2, totalReceived = 3.
    // - Send 2 wei to the contract (balance = 2, totalReleased = 3, totalReceived = 5).
    // - Call release(A): payment = floor(5*2/3) - 2 = 1; pays 1 wei; totalReleased = 4; balance = 1; released[A] = 3; totalReceived remains 5.
    // - Call release(O): payment = floor(5*1/3) - 1 = 0; else-branch executes and transfers 1 wei to owner; totalReleased stays 4; balance becomes 0; totalReceived becomes 4.
    // - Now for A: RHS = floor(4*2/3) = 2, but released[A] = 3 and releasable(A) = floor(4*2/3) - 3 = -1 (underflow → revert). 
    // Hence the property “released[A] + releasable(A) == (totalReceived * shares[A]) / totalShares” is violated (releasable(A) cannot be computed).

    function test_fair_split_eq(address o,address a, address b) public {
        vm.assume(o != address(0) && o != address(this));
        vm.assume(a != address(0) && a != address(this));
        vm.assume(b != address(0) && b != address(this));
        vm.assume(o != a && o != b && a != b );

        address[] memory payees = new address[](2);        
        payees[0] = address(o);
        payees[1] = address(a);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 2;

        vm.prank(o);
        ps = new PaymentSplitter(payees, shares);

        // B sends 3 wei to the contract
        vm.deal(address(b), 3+2);
        vm.prank(b);
        (bool success1,) = address(ps).call{value:3}("");
        assert(success1);

        ps.release(payable(o));
        ps.release(payable(a));

        vm.prank(b);
        (bool success2,) = address(ps).call{value:2}("");
        assert(success2);

        ps.release(payable(a));
        ps.release(payable(o));

        uint totalReceived = address(ps).balance + ps.getTotalReleased();

        // rhs = (totalReceived * shares[a]) / totalShares
        uint rhs = (totalReceived * ps.getShares(a)) / ps.getTotalShares();
        assertEq(rhs, 2);

        uint released_a = ps.getReleased(a);
        assertEq(released_a, 3);

        vm.expectRevert();
        uint releasable_a = ps.releasable(a);
        // lhs = released[a] + releasable(a) 

        // the rhd is defined, but the lhs is undefined
        // in this case, in the ground truth we considered the property to be true
    }
}
