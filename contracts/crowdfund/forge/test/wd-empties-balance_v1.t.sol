// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
 
import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund_v1.sol";
 
contract OwnerAttack {
    address payable c;
    function setCrowdfund(address payable _c) external { c = _c; }
    receive() external payable { selfdestruct(c); }
}
 
contract CrowdfundTest is Test {
 
    Crowdfund public c;
    uint end_donate;
    uint goal;
 
    function setUp() public {
        
        // Deploy Crowdfund
        OwnerAttack _OwnerAttack = new OwnerAttack();
        address payable owner = payable(address(_OwnerAttack));
        end_donate = block.number + 10;
        goal = 1 ether;
        c = new Crowdfund(owner, end_donate, goal);
        _OwnerAttack.setCrowdfund(payable(address(c)));
    }
 
    // wd-empties-balance:
    // after a non-reverting `withdraw`, the ETH balance of the Crowdfund contract is equal to zero.
 
    // PoC produced by GPT-5:
    //- Deploy Crowdfund with owner set to a malicious contract OwnerAttack that has
    // receive() { selfdestruct(payable(crowdfund)); }.
    // - Have users donate so that address(Crowdfund).balance >= goal while block.number <= end_donate.
    // - After block.number > end_donate, call withdraw().
    // - withdraw sends all ETH to OwnerAttack; OwnerAttack’s receive executes selfdestruct to the Crowdfund address,
    //  forcing the ETH back.
    // - withdraw returns with succ = true.
    //  The Crowdfund’s balance is now > 0 (e.g., equal to the original amount), violating the property.
 
    function test_wd_empties_balance() public {
        address user = address(123);
 
        // Before end_donate:
        vm.roll(end_donate - 1);
        vm.deal(address(c), goal);
        assert(address(c).balance >= goal);
  
        // After end_donate:
        vm.roll(end_donate + 1);
 
        vm.prank(user);
        (bool success,) = address(c).call{value: 0}(abi.encodeWithSignature("withdraw()"));
        assert(success);                                       // Ensuring withdraw() does not revert
 
        uint Crowdfund_balance_after = address(c).balance;     // Balance of Crowdfund after withdraw()
 
        // after a non-reverting `withdraw`,
        // the ETH balance of the Crowdfund contract is NOT equal to zero.
        assert(Crowdfund_balance_after != 0);
    }
 
}