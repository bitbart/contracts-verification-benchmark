// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v1.sol";

contract Drainer {
    address sink = address(0);

    receive() external payable { 
        (bool ok,) = sink.call{value: address(this).balance}(""); 
        require(ok); 
    }
}

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // release-balance-payee: 
    // for every address a in payees, after a non-reverting call to release(a) the balance of a is increased by releasable(a).

    // PoC produced by GPT-5:
    // - Create a payee contract Drainer with a payable receive() that forwards all received ETH to an external EOA sink:
    //    receive() external payable { (bool ok,) = sink.call{value: address(this).balance}(""""""""); require(ok); }
    // - Deploy PaymentSplitter with payees = [Drainer] and shares = [1].
    // - Send 1 ether to PaymentSplitter.
    // - Before calling release, releasable(Drainer) = 1 ether.
    // - Call release(Drainer). PaymentSplitter sends 1 ether to Drainer; Drainer’s receive() immediately forwards the 1 ether to sink and does not revert; release returns successfully.
    // - After the call, Drainer’s balance increased by 0, not by releasable(Drainer) (1 ether).

    function test_releasable_leq_balance() public {

        Drainer drainer = new Drainer();
        address payable a = payable(drainer);

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

        uint releasable_a = ps.releasable(a);
        assertEq(releasable_a, 1 ether);

        uint balance_a_before = address(a).balance;
        assertEq(balance_a_before, 0);

        ps.release(a);

        uint balance_a_after = address(a).balance;
        assertEq(balance_a_after, 0);
    }
}
