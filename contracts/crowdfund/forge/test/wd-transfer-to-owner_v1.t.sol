// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
 
import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund_v1.sol";
 
contract Owner {
    address payable bob;
    constructor(address payable _bob) {
        bob = _bob;
    }
    receive() external payable {
        (bool ok, ) = bob.call{value: msg.value}("");
        require(ok);
    }
}
 
contract CrowdfundTest is Test {
 
    Crowdfund public c;
    uint end_donate;
    uint goal;
    address payable owner;
 
    function setUp() public {
        
        // Deploy Crowdfund with a future deadline and a goal
        address Bob = address(123);
        Owner _Owner = new Owner(payable(Bob));
        owner = payable(address(_Owner));
        end_donate = block.number + 1;
        goal = 1 ether;
        c = new Crowdfund(owner, end_donate, goal);
    }
 
    // wd-transfer-to-owner:
    // after a non-reverting `withdraw`, the ETH balance of owner is increased by an amount equal to
    // the balance (of Crowdfund) before `withdraw` was called.
 
    // PoC produced by GPT-5:
    // - Let owner be a contract with:
    //   receive() external payable { (bool,)= bob.call{value: msg.value}(""""); }
    // - Deploy Crowdfund with this owner, end_donate = current block + 1, goal = 1 ether.
    // - Before end_donate, Alice calls donate with 10 ether.
    // - After end_donate, anyone calls withdraw.
    // - Crowdfund sends 10 ether to owner (withdraw does not revert).
    //   Owner’s receive immediately forwards all 10 ether to bob and returns true.
    // - After withdraw completes, owner’s balance has not increased by 10 ether (it remains 0),
    //   while Crowdfund’s pre-withdraw balance was 10 ether, violating the property.
 
 
    function test_wd_transfer_to_owner() public {
        address Alice = address(456);
        
        // Before end_donate:
        vm.roll(end_donate - 1);
 
        vm.deal(Alice, 11 ether);
        vm.prank(Alice);
        c.donate{value: 10 ether}();
  
        // After end_donate:
        vm.roll(end_donate + 1);
 
        uint Owner_balance_before = address(owner).balance;     // Balance of owner before withdraw()
        uint Crowdfund_balance_before = address(c).balance;      // Balance of Crowdfund before withdraw()
 
        vm.prank(Alice);
        (bool success,) = address(c).call{value: 0}(abi.encodeWithSignature("withdraw()"));
        assert(success);                                       // Ensuring withdraw() does not revert
 
        uint Owner_balance_after = address(owner).balance;           // Balance of owner after withdraw()
 
        // after a non-reverting `withdraw`, the ETH balance of owner is NOT increased by an amount equal to
        // the balance (of Crowdfund) before `withdraw` was called.
        assert(Owner_balance_after != Owner_balance_before + Crowdfund_balance_before);
    }
 
}