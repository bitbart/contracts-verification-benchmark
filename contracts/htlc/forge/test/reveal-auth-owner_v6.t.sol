// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "versions/Htlc_v6.sol";

contract HtlcTest is Test {
    Htlc htlc;

    address owner = address(0x1);
    address verifier = address(0x2);
    address attacker = address(0x3);

    uint256 constant FEE = 1 ether;
    string secret = "secret";
    function setUp() public {
        vm.deal(owner, 1 ether);
        vm.deal(attacker, 1 ether);
    }

    function test_reveal_auth_owner() public {
        vm.startPrank(owner);
        htlc = new Htlc(payable(verifier));

        bytes32 h = htlc.hashing(secret);
        htlc.commit{value: FEE}(h);

        vm.prank(attacker);
        htlc.reveal{value: FEE}(secret);

        assertTrue(htlc.owner() == attacker);
    }
}