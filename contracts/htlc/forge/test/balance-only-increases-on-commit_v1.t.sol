// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "../src/Htlc_v1.sol";

// Helper contract used to force-send ETH into the Htlc contract via selfdestruct
contract Attacker {
    constructor() payable {}

    function destroy(address payable target) public {
        selfdestruct(target);
    }
}

contract HtlcTest is Test {
    Htlc htlc;

    uint256 constant FEE = 1 ether;

    address owner = address(0x1);
    address verifier = address(0x2);
    address attacker = address(0x3);
    
    string secret = "secret";
    
    function setUp() public {
        vm.deal(owner, FEE);
    }

    function test_balance_only_increases_on_commit() public {
        vm.prank(owner);
        htlc = new Htlc(payable(verifier));

        assertEq(address(htlc).balance, 0);
        assertFalse(htlc.isCommitted());

        vm.deal(attacker, FEE);
        vm.startPrank(attacker);

        Attacker att = new Attacker{value: FEE}();

        uint256 _pre_bal = address(htlc).balance;

        att.destroy(payable(address(htlc)));

        uint256 _post_bal = address(htlc).balance;

        assertGt(_post_bal, _pre_bal);
        assertFalse(htlc.isCommitted());
    }
    
}