// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "../src/Htlc_v12.sol";

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

    function test_wrong_preimage_reverts_v12() public {
        vm.startPrank(owner);

        htlc = new Htlc(payable(verifier));

        bytes32 h = htlc.hashing(secret);
        htlc.commit{value: FEE}(h);

        vm.expectRevert();
        htlc.reveal("wrong");
    }
}