// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v7.sol";

contract A {
    // no method to call release()
}

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // tx-transfer-releasable-receive:
    // if `releasable(a) > 0` and the address `a` has a `receive` method that just accepts all ETH, 
    // then someone can perform a transaction on PaymentSplitter that transfers ETH 
    // from the contract to `a`.

    // PoC produced by GPT-5:
    // NONE

    function test_tx_transfer_releasable_receive() public {

        A a_contract = new A();

        address a = address(a_contract);
        address b = address(0x2);

        address[] memory payees = new address[](1);        
        payees[0] = address(a);
        
        uint256[] memory shares = new uint256[](1);
        shares[0] = 1;

        // Deploy PaymentSplitter
        vm.deal(address(this), 5);
        ps = new PaymentSplitter{value: 5}(payees, shares);
        assertEq(address(ps).balance, 5);

        assertEq(ps.releasable(a), 5);

        vm.prank(a);
        vm.expectRevert();
        ps.release(payable(a));
    }
}
