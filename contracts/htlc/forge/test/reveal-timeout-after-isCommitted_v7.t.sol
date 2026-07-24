// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "../src/Htlc_v7.sol";

contract HtlcTest is Test {
    Htlc htlc;

    address owner = address(0x1);
    address verifier = address(0x2);

    uint256 constant FEE = 1 ether;
    string secret = "secret";
    function setUp() public {
        vm.deal(owner, 1 ether);
    }

    function test_timeout_after_isCommitted_v7() public {
        vm.startPrank(owner);
        htlc = new Htlc(payable(verifier));

        vm.roll(htlc.start() + htlc.waitTime() + 1);
        vm.expectRevert();
        htlc.timeout();
    }
}