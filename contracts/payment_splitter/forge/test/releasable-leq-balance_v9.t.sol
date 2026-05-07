// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v9.sol";

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // releasable-leq-balance: 
    // for all addresses addr in payees, releasable(addr) is less than or equal to the balance of the contract.

    // PoC produced by GPT-5:
    // - Deploy with payees [A (owner), B], shares [50, 50].
    // - Send 2000 wei to the contract.
    // - Call release(B): payment = 1000 wei to B; totalReleased = 1000; released[B] = 1000; balance = 1000.
    // - Repeatedly call release(C) for some non-payee C (shares[C] = 0) so payment == 0 and the else-branch executes, 
    //   sending 1 wei to owner each time. Do this 1000 times to drain the balance to 0. Note: totalReleased stays 1000 throughout.
    // - Now, releasable(A) = ((balance + totalReleased) * 50 / 100) - released[A] = ((0 + 1000) * 50 / 100) - 0 = 500 > balance (0).

    function test_releasable_leq_balance() public {

        address a = address(0x1);
        address b = address(0x2);
        address c = address(0x3);

        address[] memory payees = new address[](2);        
        payees[0] = address(a);
        payees[1] = address(b);
        
        uint256[] memory shares = new uint256[](2);
        shares[0] = 50;
        shares[1] = 50;

        vm.prank(a);
        ps = new PaymentSplitter(payees, shares);

        // C sends 2000 wei to the contract
        vm.deal(address(c), 2000);
        vm.prank(c);
        (bool success1,) = address(ps).call{value:2000}("");
        assert(success1);

        ps.release(payable(b));

        for (int i=0; i<1000; i++)
            ps.release(payable(c));

        uint releasable_a = ps.releasable(a);
        assertEq(releasable_a, 500);
        assertEq(address(ps).balance, 0);
    }
}
