// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v3.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // tx-transfer-releasable-receive:
    // if `releasable(a) > 0` and the address `a` has a `receive` method that just accepts all ETH, 
    // then someone can perform a transaction on PaymentSplitter that transfers ETH 
    // from the contract to `a`.

    // PoC produced by GPT-5:
    // - Deploy PaymentSplitter with payees P1, P2, P3 (distinct nonzero addresses).
    // - Let A be an address not among {P1, P2, P3}, with a receive() payable {} that accepts ETH.
    // - Send 3 wei to the contract (so address(this).balance = 3, totalReleased = 0).
    // - Then releasable(A) = (3 + 0) / 3 - 0 = 1 > 0.
    // - Any call to release(A) reverts at require(shares[A] > 0) or require(isPayee(A)), so no ETH can be transferred to A from the contract.

    function test_release_release_revert() public {

        // Deploy
        address p1 = address(0x1);
        address p2 = address(0x2);
        address p3 = address(0x3);
        address a  = address(0x4);

        vm.deal(address(this), 5);
        ps = new PaymentSplitter{value:3}(p1,p2,p3);

        assertEq(ps.releasable(payable(a)), 1);

        vm.expectRevert();
        ps.release(payable(a));
    }
}
