// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "../src/Htlc_v2.sol";

contract HtlcTest is Test {
    Htlc htlc;

    address owner = address(0x1);
    address verifier = address(0x2);

    uint256 constant FEE = 1 ether;

    function setUp() public {
        vm.deal(owner, 2*FEE);
    }

    function test_commit_reverts_if_isCommitted() public {
        vm.startPrank(owner);
        htlc = new Htlc(payable(verifier));
        
        htlc.commit{value: FEE}(htlc.hashing("secret1"));

        htlc.commit{value: FEE}(htlc.hashing("secret2"));
    }
}

