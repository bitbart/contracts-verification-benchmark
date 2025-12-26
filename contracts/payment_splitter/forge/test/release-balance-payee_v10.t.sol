// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v10.sol";

contract Attack {
    address splitter = address(0);

    receive() external payable { 
        (bool ok,) = address(splitter).call{value: msg.value}(""); 
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
    // - Deploy PaymentSplitter with payees = [Attack], shares = [1].
    // - Fund the splitter with 1 ether.
    // - Attack is a contract with:
    //  - receive() external payable { (bool ok,) = address(splitter).call{value: msg.value}(""""""""); require(ok); }
    // - Before calling release, releasable(Attack) = 1 ether.
    // - Call release(payable(Attack)). PaymentSplitter sends 1 ether to Attack; Attack’s receive immediately sends the 1 ether back to the splitter (receive on splitter succeeds). 
    // The call does not revert.
    // - Final state: Attack’s balance is unchanged (0), while releasable(Attack) pre-call was 1 ether. Hence the balance of Attack did not increase by releasable(Attack).

    function test_releasable_leq_balance() public {

        Attack attack = new Attack();
        address payable a = payable(attack);

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
