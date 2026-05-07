// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v3.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // release-release-revert: 
    // two consecutive calls to release for the same address a, without there being any ETH transfer 
    // to the contract in-between calls, revert on the second call.

    // PoC produced by GPT-5:
    // - Deploy PaymentSplitter with payees: [A = this contract’s address, B, C], and send 5 wei to the constructor.
    // - Initial: balance = 5, totalReleased = 0, released[A] = 0.
    // - First call: release(A):
    //    - totalReceived = 5 + 0 = 5; payment = floor(5/3) - 0 = 1.
    //    - Update: totalReleased = 1; released[A] = 1.
    //    - Send 1 wei to A (the contract itself). Net balance remains 5; call succeeds.
    // - Second call (no ETH sent to the contract in-between): release(A):
    //    - totalReceived = balance + totalReleased = 5 + 1 = 6.
    //    - payment = floor(6/3) - released[A] = 2 - 1 = 1 > 0.
    //  - The second call does not revert, violating the property.

    // Note that we do not consider the following PoC as a violation to the property,
    // since we assume that the address a does not coincide with the contract itself
    // In the prompt, we require that: 
    //   "when in a property we refer to a ""user"" of the contract, 
    //    we implicitly assume that the user is not the contract under analysis itself"
    // There is however some ambiguity related to the fact that in the property we write "address" instead of "user"

    function test_release_release_revert() public {
       address deployer = address(this);

        // Nonce *before* deployment
        uint256 nonce = vm.getNonce(deployer);

        // Compute expected address
        address a = computeCreateAddress(deployer, nonce);

        // Deploy
        address b = address(0x2);
        address c = address(0x3);

        vm.deal(address(this), 5);
        ps = new PaymentSplitter{value:5}(a,b,c);

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
