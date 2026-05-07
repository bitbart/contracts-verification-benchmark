// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
 
import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund_v1.sol";
 
contract RevertingOwner {
    receive() external payable { revert(); }
}
 
contract CrowdfundTest is Test {
 
    Crowdfund public c;
    uint constant N = 100;
    uint end_donate;
    uint goal;
 
    function setUp() public {
        
        // Deploy Crowdfund with a future deadline and a goal
        RevertingOwner _RevertingOwner = new RevertingOwner();
        address payable owner = payable(address(_RevertingOwner));
        end_donate = N;
        goal = 1 wei;
        c = new Crowdfund(owner, end_donate, goal);
    }
 
    // wd-not-revert:
    // a transaction `withdraw` is not reverted if the contract balance is greater than or equal to the goal
    // and the donation phase has ended.
 
 
    // PoC produced by GPT-5:
    // - Deploy a contract RevertingOwner with:
    //   - receive() external payable { revert(); }
    // - Deploy Crowdfund with:
    //   - owner_ = address of RevertingOwner
    //   - end_donate_ = some block N
    //   - goal_ = 1 wei
    // - Before block N, call donate() with msg.value = 1 wei (now address(this).balance = 1 wei).
    // - After block N (so block.number > end_donate), call withdraw().
    // - The call to owner.call(...) triggers RevertingOwner.receive(), which reverts; succ == false; require(succ) reverts the withdraw() transaction, violating the property.
 
 
    function test_wd_not_revert() public {
        address user = address(123);
 
        // Before block N: call donate() with msg.value = 1 wei
        vm.roll(end_donate - 10);
 
        vm.deal(user, 1 ether);
        vm.prank(user);
        c.donate{value: 1 wei}();
 
        assert(address(c).balance == 1 wei);
 
        // After block N: call withdraw()
        vm.roll(end_donate + 1);
        assert(block.number > end_donate);
 
        // Check whether all require checks in withdraw() pass
        assert(block.number > end_donate);
        assert(address(c).balance >= goal);
 
        // a transaction `withdraw` IS reverted even if the contract balance is greater than or equal to the goal
        // and the donation phase has ended.
        vm.expectRevert();
        vm.prank(user);
        c.withdraw();
    }
 
}
 