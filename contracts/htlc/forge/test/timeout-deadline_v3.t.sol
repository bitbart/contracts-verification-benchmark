// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "../src/Htlc_v3.sol";

contract HtlcTest is Test {
    Htlc htlc;

    address owner = address(0x1);
    address verifier = address(0x2);

    uint256 constant FEE = 1 ether;
    string secret = "secret";

    uint256 start;
    uint256 waitTime;
    uint256 target;
    
    function setUp() public {
        vm.deal(owner, 1 ether);
    }

    function test_timeout_deadline() public {
        vm.startPrank(owner);

        htlc = new Htlc(payable(verifier));
        start = htlc.start();
        waitTime = htlc.waitTime();

        bytes32 h = htlc.hashing(secret);
        htlc.commit{value: 1 ether}(h);

        target = start + waitTime - 1;
        vm.roll(target);

        // Sanity check
        assertLt(block.number, start + waitTime);

        htlc.timeout();
    }
}