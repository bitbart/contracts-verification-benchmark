// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
 
import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund_v1.sol";
 
 
contract A {
    address payable B;
    constructor(address payable _B) {
        B = _B;
    }
    receive() external payable { payable(B).call{value: msg.value}(""); }
    function trigger(Crowdfund c) external { c.reclaim(); }
}
 
contract CrowdfundTest is Test {
 
    Crowdfund public c;
    uint end_donate;
    uint goal;
 
    function setUp() public {
        
        // Deploy Crowdfund with a future deadline and a goal
        address payable owner = payable(address(this));
        end_donate = 1;
        goal = 100 wei;
        c = new Crowdfund(owner, end_donate, goal);
    }
 
    // reclaim-own-funds:
    // after a non-reverting `reclaim` by `msg.sender` A,
    // the ETH balance of A is increased by an amount equal to
    // `donation[A]` before `reclaim` was called.
 
    // PoC produced by GPT-5:
    // - Deploy Crowdfund with end_donate=1, goal=100 wei.
    // - Let A be a contract with:
    //   receive() external payable { payable(B).call{value: msg.value}(""""); }
    //   function trigger(Crowdfund c) external { c.reclaim(); }
    // - Before block 1: A donates 10 wei via c.donate{value:10}(), and another user donates 20 wei.
    //   Now c’s balance = 30 < 100.
    // - After block > 1, call A.trigger(c).
    //   In reclaim(), amount=10; donation[A]=0; then c sends 10 wei to A.
    //   A’s receive forwards the 10 wei to B, the call returns true, and reclaim completes successfully.
    // - A’s ETH balance after the call is unchanged (not increased by 10 wei), violating the property.
 
    function test_reclaim_own_funds() public {
        address B = address(123);
        A _A = new A(payable(B));
        address user = address(456);
 
        // Before end_donate
        vm.roll(end_donate - 1);
 
        vm.deal(address(_A), 1 ether);
        vm.prank(address(_A));
        c.donate{value: 10}();
 
        vm.deal(user, 1 ether);
        vm.prank(user);
        c.donate{value: 20}();
  
        // After end_donate
        vm.roll(end_donate + 1);
 
        uint A_balance_before = address(_A).balance;     // Balance of A before reclaim()
 
        (bool success,) = address(_A).call{value: 0}(abi.encodeWithSignature("trigger(address)",address(c)));
        assert(success);                                // Ensuring reclaim() does not revert
 
        uint A_balance_after = address(_A).balance;     // Balance of A after reclaim()
 
        // after a non-reverting `reclaim` by `msg.sender` A,
        // the ETH balance of A is NOT increased by an amount equal to
        // `donation[A]` before `reclaim` was called.
        assert(A_balance_before == A_balance_after);
    }
 
}