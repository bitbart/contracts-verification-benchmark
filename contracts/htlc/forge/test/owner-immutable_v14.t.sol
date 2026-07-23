// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "../../versions/Htlc_v14.sol";

contract HtlcTest is Test {
    Htlc htlc;

    unit256 constant FEE = 1 ether;

    address owner = address(0x1);
    address verifier = address(0x2);
    address attacker = address(0x3);

    string secret = "secret";
    function setUp() public {
        vm.deal(owner, FEE);
        vm.deal(attacker, FEE);
    }
    
    function test_owner_immutable() public {
        vm.startPrank(owner);
        htlc = new Htlc(payable(verifier));

        assertTrue(htlc.owner() == owner);
        bytes32 hash = htlc.hashing(secret);
        htlc.commit{value: FEE}(hash);

        vm.stopPrank();
        vm.startPrank(attacker);
        htlc.reveal{value: FEE}(secret);

        assertTrue(htlc.owner() == attacker);
    }
}