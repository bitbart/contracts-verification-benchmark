// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v1.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // release-release-revert-receive: 
    // two consecutive calls to release for the same address a, without there being any ETH transfer 
    // to the contract in-between calls, revert on the second call.

    // PoC produced by GPT-5:
    // NONE

    // Note that we do not consider the following PoC as a violation to the property,
    // since we assume that the address a does not coincide with the contract itself
    // In the prompt, we require that: 
    //   "when in a property we refer to a ""user"" of the contract, 
    //    we implicitly assume that the user is not the contract under analysis itself"
    // There is however some ambiguity related to the fact that in the property we write "address" instead of "user"

    function test_release_release_revert_receive() public {
       address deployer = address(this);

        // Nonce *before* deployment
        uint256 nonce = vm.getNonce(deployer);

        // Compute expected address
        address a = computeCreateAddress(deployer, nonce);
        address b = address(0x2);

        address[] memory payees = new address[](2);        
        payees[0] = address(a);
        payees[1] = address(b);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 1;

        // Deploy PaymentSplitter
        vm.deal(address(this), 5);
        ps = new PaymentSplitter{value: 5}(payees, shares);

        // Verify
        assertEq(address(ps), a);
        assertEq(address(ps).balance, 5);

        vm.prank(b);
        ps.release(payable(a));
        assertEq(address(a).balance, 5);

        vm.prank(b);
        ps.release(payable(a));
        assertEq(address(a).balance, 5);
    }
}
