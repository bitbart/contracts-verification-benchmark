// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v2.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // release-not-revert-receive: 
    // if the address a is in payees, and its receive method just accepts all ETH, and releasable(a) > 0, 
    // then release(a) does not revert

    // PoC produced by GPT-5:
    // - Deploy with payees A, B, C each having shares > 0 (e.g., 1,1,1).
    // - Send 3 wei to the contract so releasable(B) == 1 > 0.
    // - Call release(B) while attaching any ETH (e.g., msg.value = 1 wei). 
    // Because release is nonpayable, the call reverts despite B being a payee and having releasable > 0 and its receive accepting ETH."

    function test_release_not_revert_receive() public {
        address a = address(0x1);
        address b = address(0x2);
        address c = address(0x3);
        
        vm.prank(address(a));
        ps = new PaymentSplitter(a,1,b,1,c,1);

        // A sends 3 wei to the contract
        vm.deal(address(a), 3);
        vm.prank(a);
        (bool success1,) = address(ps).call{value:3}("");
        assert(success1);

        vm.prank(b);
        (bool ok,) = address(ps).call{value:1}(abi.encodeWithSignature("release(address)", b));
        assert(!ok);
    }
}
