// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v9.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // tx-transfer-balance-receive: 
    // if the contract balance is non-zero and all payees are EOAs, then eventually 
    // someone can perform a transaction on PaymentSplitter that decreases the contract balance.

    // PoC produced by GPT-5:
    // 1) Deploy PaymentSplitter with payees_ = [A] where A = msg.sender (EOA), shares_ = [0], and send 1 ether in the constructor call (contract balance = 1 ether).
    // 2) All payees are EOAs, but shares[A] = 0 and totalShares = 0.
    // 3) Any call to release(A) reverts at require(shares[account] > 0).
    // 4) No other function can decrease the balance. Therefore, despite non-zero balance and all payees being EOAs, no transaction can reduce the contract balance.

    function test_tx_transfer_balance_receive() public {

        address a = address(0x1);

        address[] memory payees = new address[](1);        
        payees[0] = address(a);
        
        uint256[] memory shares = new uint256[](1);
        shares[0] = 0;

        vm.deal(address(a), 1 ether);
        vm.prank(a);
        ps = new PaymentSplitter{value: 1 ether}(payees, shares);
        assertEq(address(ps).balance, 1 ether);
    
        vm.prank(a);
        vm.expectRevert();
        ps.release(payable(a));
    }
}
