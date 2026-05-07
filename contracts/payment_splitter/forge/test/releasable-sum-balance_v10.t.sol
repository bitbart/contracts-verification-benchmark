// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v10.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // releasable-sum-balance: 
    // the sum of the releasable funds for every addresses is equal to the balance of the contract.

    // PoC produced by GPT-5:
    // - Deploy with payees [A,B,C] and shares [1,1,1] (totalShares = 3).
    // - Send 1 wei to the contract.
    // - For each payee, releasable = floor((1 wei + 0) * 1 / 3) - 0 = 0; sum of releasable = 0.
    // - Contract balance = 1 wei.
    // - Hence, sum of releasable funds (0) != contract balance (1 wei).

    function test_releasable_leq_balance() public {

        address a = address(0x1);
        address b = address(0x2);
        address c = address(0x3);

        address[] memory payees = new address[](3);        
        payees[0] = address(a);
        payees[1] = address(b);
        payees[2] = address(c);
        
        uint256[] memory shares = new uint256[](3);
        shares[0] = 1;
        shares[1] = 1;
        shares[2] = 1;

        vm.prank(a);
        ps = new PaymentSplitter(payees, shares);

        // A sends 1 wei to the contract
        vm.deal(address(a), 1);
        vm.prank(a);
        (bool success1,) = address(ps).call{value:1}("");
        assert(success1);

        uint releasable_a = ps.releasable(a);
        uint releasable_b = ps.releasable(b);
        uint releasable_c = ps.releasable(c);
        assertEq(releasable_a + releasable_b + releasable_c, 0);
        assertEq(address(ps).balance, 1);
    }
}
