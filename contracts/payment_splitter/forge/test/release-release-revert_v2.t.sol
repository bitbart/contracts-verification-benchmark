// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v2.sol";

contract A {

    address receiver;

    function setReceiver(address rcv) external { 
        receiver = rcv;
    }

    fallback() payable external {
        (bool ok,) = receiver.call{value: 3}(""); 
        require(ok, "receiver did not accepted 3 wei"); 
    }
}

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // release-release-revert: 
    // two consecutive calls to release for the same address a, without there being any ETH transfer 
    // to the contract in-between calls, revert on the second call.

    // PoC produced by GPT-5:
    // - Deploy with payees A, B, C and shares 1, 1, 1 respectively, where A is a contract whose payable fallback, upon receiving ETH, 
    // immediately sends 3 wei to the PaymentSplitter.
    // - Fund the PaymentSplitter with 3 wei.
    // - Call release(A):
    //    - Before callback: payment = floor((3 + 0) * 1 / 3) - 0 = 1 wei.
    //  - State updates: totalReleased = 1; released[A] = 1.
    //    - External call sends 1 wei to A; A’s fallback immediately sends 3 wei to PaymentSplitter (receive() accepts it).
    //    - After the call: balance = 3 - 1 + 3 = 5; totalReleased = 1.
    // - Without any ETH transfer to the contract between calls, call release(A) again:
    //    - Now releasable(A) = floor((5 + 1) * 1 / 3) - 1 = floor(6/3) - 1 = 2 - 1 = 1 wei > 0, so the call does NOT revert.

    function test_release_release_revert() public {
        A a_contract = new A();

        // we need to fund the contract, otherwise the PoC reverts when the fallback is executed   
        vm.deal(address(a_contract), 4);

        address a = address(a_contract);
        address b = address(0x2);
        address c = address(0x3);
        
        vm.prank(address(b));
        ps = new PaymentSplitter(b,1,a,1,c,1);

        a_contract.setReceiver(address(ps));

        // B sends 3 wei to the contract
        vm.deal(address(b), 3);
        vm.prank(b);
        (bool success1,) = address(ps).call{value:3}("");
        assert(success1);

        assertEq(address(ps).balance, 3);

        vm.prank(b);
        ps.release(payable(a));
        ps.release(payable(a));
    }
}
