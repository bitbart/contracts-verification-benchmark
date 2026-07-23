// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "../../versions/Htlc_v7.sol";

contract HtlcTest is Test {
    Htlc htlc;

    uint256 constant FEE = 1 ether;

    address owner = address(0x1);
    address verifier = address(0x2);
    
    string secret = "secret";
    
    function setUp() public {
        vm.deal(owner, FEE);
    }
    
    function test_cant_uncommit() public {
        vm.startPrank(owner);
        htlc = new Htlc(payable(verifier));

        bytes32 hash = htlc.hashing(secret);
        htlc.commit{value: FEE}(hash);

        assertTrue(htlc.isCommitted);
        htlc.reveal(secret);
        assertFalse(htlc.isCommitted);
    }
}