// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PaymentSplitter} from "../src/PaymentSplitter_v7.sol";

contract Forwarder {
    address owner;
    constructor(address owner_) { owner = owner_; }
    function claim(PaymentSplitter ps) external { ps.release(payable(address(this))); }
    receive() external payable { payable(owner).call{value: address(this).balance}(""); } // forwards all received ETH out
}

contract PaymentSplitterTest is Test {

    PaymentSplitter public ps;

    function setUp() public {
    }

    // release-balance-payee: 
    // for every address a in payees, after a non-reverting call to release(a) the balance of a is increased by releasable(a).

    // PoC produced by GPT-5:
    // - Let a be a contract Forwarder with:
    //   - function claim(PaymentSplitter ps) external { ps.release(payable(address(this))); }
    //   - receive() external payable { payable(owner).call{value: address(this).balance}(""""""""); } // forwards all received ETH out
    // - Deploy PaymentSplitter with payees = [a], shares = [1].
    // - Send 10 ETH to PaymentSplitter.
    // - Call a.claim(ps). This makes msg.sender == a for ps.release(a), so it does not revert. Pre-call, releasable(a) = 10 ETH. release() computes payment = 10 ETH, updates accounting, then calls a with 10 ETH. a’s receive forwards the 10 ETH to owner and returns success; release() returns successfully.
    // - Final state: balance(a) has not increased (it is 0), but releasable(a) before the call was 10 ETH. Hence the balance of a did not increase by releasable(a).

    function test_releasable_leq_balance() public {
        address o = address(0x1);
        
        Forwarder f = new Forwarder(o);
        address payable a = payable(f);

        address[] memory payees = new address[](1);        
        payees[0] = address(a);
        
        uint256[] memory shares = new uint256[](1);
        shares[0] = 1;

        vm.prank(address(a));
        ps = new PaymentSplitter(payees, shares);

        // A sends 10 ether to the contract
        vm.deal(address(a), 10 ether);
        vm.prank(a);
        (bool success1,) = address(ps).call{value:10 ether}("");
        assert(success1);

        uint releasable_a = ps.releasable(a);
        assertEq(releasable_a, 10 ether);

        uint balance_a_before = address(a).balance;
        assertEq(balance_a_before, 0);

        vm.prank(a);
        ps.release(a);

        uint balance_a_after = address(a).balance;
        assertEq(balance_a_after, 0);
    }
}
