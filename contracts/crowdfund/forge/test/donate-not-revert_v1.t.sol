// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;
 
import {Test} from "forge-std/Test.sol";
import {Crowdfund} from "../src/Crowdfund_v1.sol";
 
contract CrowdfundTest is Test {
 
    Crowdfund public c;
 
    function setUp() public {

        address payable owner = payable(address(this));
        uint end_donate = block.number + 10;
        uint goal = 2 ether;

        c = new Crowdfund(owner, end_donate, goal);
    }


    // donate-not-revert:
    // a transaction `donate` is not reverted if
    // the donation phase has not ended.

    // PoC:
    // - the overflow is induced by two transactions:
    // the first one with the maximum amount for uint256;
    // the second with only 1.

    function test_donate_not_revert() public {

        address user = address(0x1234);
        uint amount = type(uint).max;

        vm.deal(user, amount);

        // The following does not pass because it fails to reach overflow
        // vm.deal(user, amount - 1); 

        vm.prank(user);
        (bool success,) = address(c).call{value: amount}(abi.encodeWithSignature("donate()"));
        assert(success);

        vm.deal(user, 1);
        
        vm.prank(user);
        (bool succ,) = address(c).call{value: 1}(abi.encodeWithSignature("donate()"));
        assert(!succ);
    }
}