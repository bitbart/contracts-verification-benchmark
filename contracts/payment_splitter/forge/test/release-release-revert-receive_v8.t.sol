// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v8.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // release-release-revert-receive: 
    // if the `receive` method of the address `a` just accepts all ETH, two consecutive calls to `release` for `a`, 
    // without there being any ETH transfer to the contract in-between calls, revert on the second call.

    // PoC produced by GPT-5:
    // - Deploy with payees [owner, A] and shares [1, 1] (constructor requires the first payee be the owner).
    // - Send 2 wei to the contract.
    // - Call release(A): payment = (2 * 1) / 2 - 0 = 1 wei. A receives 1 wei; contract balance becomes 1 wei; totalReleased = 1.
    // - Call release(A) again without any new deposit: payment = ( (balance 1 + totalReleased 1) * 1 / 2 ) - alreadyReleased 1 = (2/2) - 1 = 0. The else branch executes and sends 1 wei to owner, which succeeds since balance is 1 wei. No revert occurs.
    // Thus, the second call does not revert, contradicting the property.

    function test_release_release_revert_receive() public {

        address owner = address(0x1);
        address a = address(0x2);
        
        address[] memory payees = new address[](2);        
        payees[0] = address(owner);
        payees[1] = address(a);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 1;

        vm.prank(address(owner));
        ps = new PaymentSplitter(payees, shares);

        // owner sends 2 wei to the contract
        vm.deal(address(owner), 3);
        vm.prank(owner);
        (bool success1,) = address(ps).call{value:2}("");
        assert(success1);

        vm.prank(a);
        ps.release(payable(a));
        ps.release(payable(a));
    }
}
