// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v7.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // release-not-revert-receive: 
    // if the address a is in payees, and its receive method just accepts all ETH, and releasable(a) > 0, 
    // then release(a) does not revert

    // PoC produced by GPT-5:
    // - Deploy with payees = [Alice], shares = [1].
    // - Fund the contract with 1 ether so releasable(Alice) > 0.
    // - Bob (not Alice) calls release(Alice).
    // - The call reverts with "PaymentSplitter: can only be called by the payee".

    function test_release_not_revert_receive() public {
        address a = address(0x1);
        address b = address(0x2);
        
        address[] memory payees = new address[](1);        
        payees[0] = address(a);
        
        uint256[] memory shares = new uint256[](1);
        shares[0] = 1;

        vm.prank(address(a));
        ps = new PaymentSplitter(payees, shares);

        // A sends 1 ether to the contract
        vm.deal(address(a), 1 ether);
        vm.prank(a);
        (bool success1,) = address(ps).call{value:1 ether}("");
        assert(success1);

        vm.prank(b);
        vm.expectRevert();
        ps.release(payable(b));
    }
}
