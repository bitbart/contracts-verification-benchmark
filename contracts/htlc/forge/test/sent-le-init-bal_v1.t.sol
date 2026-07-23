// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "versions/Htlc_v1.sol";

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

    function test_timeout_transfer() public {
        vm.startPrank(owner);
        htlc = new Htlc(verifier);
        assertEq(address(h).balance, 0);

        // Owner commits a hash
        bytes32 h = htlc.hashing(secret);
        htlc.commit{value: FEE}(h);

        assertTrue(htlc.isCommitted());
        assertEq(address(htlc).balance, FEE);

        // An unrelated attacker forces additional ETH into the contract after commit()
        uint256 forcedAmount = 2*FEE;
        vm.deal(attacker, forcedAmount);
        vm.prank(attacker);
        Attacker att = new Attacker{value: forcedAmount}();

        vm.prank(attacker);
        att.destroy(payable(address(htlc)));

        assertEq(address(htlc).balance, FEE + forcedAmount);

        // Owner reveals the preimage; the whole contract balance is sent to owner
        uint256 ownerBalBefore = owner.balance;

        vm.prank(owner);
        htlc.reveal(secret);

        uint256 ownerBalAfter = owner.balance;
        uint256 amountSent = ownerBalAfter - ownerBalBefore;

        // The amount actually sent out exceeds the initial deposit made in commit()
        assertEq(amountSent, FEE + forcedAmount);
        assertGt(amountSent, FEE);
    }
}
