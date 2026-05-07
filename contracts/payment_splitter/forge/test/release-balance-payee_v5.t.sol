// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v5.sol";

contract P { 
    address payable sink; 
    constructor(address payable s) {sink=s;} 
    receive() external payable { sink.transfer(msg.value); } 
}

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // release-balance-payee: 
    // for every address a in payees, after a non-reverting call to release(a) the balance of a is increased by releasable(a).

    // PoC produced by GPT-5:
    // - Deploy PaymentSplitter with a single payee P and shares [1] (so that release does not revert due to the integer-division bug in pendingPayment).
    // - Fund the splitter with 1 ether.
    // - Let P be a contract:
    //   - contract P { address payable sink; constructor(address payable s){sink=s;} receive() external payable { sink.transfer(msg.value); } }
    // - Pre-state: balance(P) = 0; releasable(P) = 1 ether (since shares/totalShares = 1).
    // - Call release(P). It does not revert and sends 1 ether to P. P’s receive immediately forwards the 1 ether to sink and returns true, so release succeeds.
    // - Post-state: balance(P) = 0 (no net increase), while releasable(P) before the call was 1 ether. This violates the property.

    function test_releasable_leq_balance() public {

        address b = address(0x1);

        P p = new P(payable(address(0)));
        address payable a = payable(p);

        address[] memory payees = new address[](1);        
        payees[0] = address(a);
        
        uint256[] memory shares = new uint256[](1);
        shares[0] = 1;

        vm.prank(address(a));
        ps = new PaymentSplitter(payees, shares);

        // B sends 1 ether to the contract
        vm.deal(address(b), 1 ether);
        vm.prank(b);
        (bool success1,) = address(ps).call{value:1 ether}("");
        assert(success1);

        uint releasable_a = ps.releasable(a);
        assertEq(releasable_a, 1 ether);

        uint balance_a_before = address(a).balance;
        assertEq(balance_a_before, 0);

        ps.release(a);

        //uint balance_a_after = address(a).balance;
        //assertEq(balance_a_after, 0);
    }
}
