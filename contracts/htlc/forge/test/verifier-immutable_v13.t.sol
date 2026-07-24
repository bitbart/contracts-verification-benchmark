// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "../src/Htlc_v13.sol";

contract HtlcTest is Test {
    Htlc htlc;

    address owner = address(0x1);
    address verifier = address(0x2);
    address attacker = address(0x3);

    uint256 constant FEE = 1 ether;
    string secret = "secret";

    uint256 start;
    uint256 waitTime;
    
    function setUp() public {
        vm.deal(owner, FEE);
    }

    function test_verifier_immutable() public {
        vm.startPrank(owner);

        htlc = new Htlc(payable(verifier));
        start = htlc.start();
        waitTime = htlc.waitTime();

        bytes32 h = htlc.hashing(secret);
        htlc.commit{value: FEE}(h);

        vm.roll(start + waitTime);

        vm.expectRevert();
        htlc.timeout{value: FEE}();

        assertFalse(htlc.verifier() != verifier);
        assertFalse(htlc.verifier() == attacker);
    }
}