// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "../src/Htlc_v9.sol";

contract HtlcTest is Test {
    Htlc htlc;

    address owner = address(0x1);
    address verifier = address(0x2);

    uint constant FEE = 1 ether;

    string secret = "secret";
    function setUp() public {
        vm.deal(owner, 1 ether);
    }

    function test_commit_minimum() public {
        vm.startPrank(owner);
        htlc = new Htlc(payable(verifier));
        assertFalse(htlc.isCommitted());

        bytes32 h = htlc.hashing(secret);
        htlc.commit{value: 0}(h);

        assertTrue(htlc.isCommitted());
    }
}