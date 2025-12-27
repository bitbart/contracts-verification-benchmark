// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v10.sol";

contract A {

    address receiver;

    function setReceiver(address rcv) external { 
        receiver = rcv;
    }

    fallback() payable external {
        (bool ok,) = receiver.call{value: 1}(""); 
        require(ok, "receiver did not accepted 1 wei"); 
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
    // NONE

    function test_release_release_revert() public {
        A a_contract = new A();

        // we need to fund the contract, otherwise the PoC reverts when the fallback is executed   
        vm.deal(address(a_contract), 4);

        address a = address(a_contract);
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
        assertEq(address(ps).balance, 5);
    
        a_contract.setReceiver(address(ps));

        vm.prank(b);
        ps.release(payable(a));
        ps.release(payable(a));
    }
}
