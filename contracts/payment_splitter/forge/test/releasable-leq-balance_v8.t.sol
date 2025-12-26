// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v8.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // releasable-leq-balance: 
    // for all addresses addr in payees, releasable(addr) is less than or equal to the balance of the contract.

    // PoC produced by GPT-5:
    // - Setup: Deploy with payees [owner (deployer), Bob] and shares [1, 1]. 
    // - Send 2 wei to the contract. 
    // - Call release(owner): payment = 1 wei, updates totalReleased = 1 and released[owner] = 1, balance becomes 1. 
    // - Call release(owner) again: payment = 0, so the else branch sends 1 wei to owner; balance becomes 0, totalReleased remains 1. 
    // - Now calling releasable(owner) uses totalReceived = balance + totalReleased = 0 + 1 = 1 
    //   and computes (1*1)/2 - released[owner] = 0 - 1, which underflows and reverts. 
    // Thus the property fails for this payee."

    function test_releasable_leq_balance(address o,address a, address b) public {

        address o = address(0x1);
        address a = address(0x2);
        address b = address(0x3);

        address[] memory payees = new address[](2);        
        payees[0] = address(o);
        payees[1] = address(b);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 1;

        vm.prank(o);
        ps = new PaymentSplitter(payees, shares);

        // A sends 2 wei to the contract
        vm.deal(address(a), 2);
        vm.prank(a);
        (bool success1,) = address(ps).call{value:2}("");
        assert(success1);

        ps.release(payable(o));
        ps.release(payable(o));

        vm.expectRevert();
        uint releasable_o = ps.releasable(o);
        // releasable(o) is undefined
    }
}
