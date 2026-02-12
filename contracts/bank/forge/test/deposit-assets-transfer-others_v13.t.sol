// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v13.sol";


contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // deposit-assets-transfer-others:
    // after a non-reverting deposit(), the ETH balance of any user but the sender are preserved.

    // PoC produced by GPT-5:
    // Deployment by EOA Owner.
    // Then Alice (not the owner) calls deposit() with msg.value = 2 wei.
    // The call does not revert.
    // As a result, owner’s ETH balance increases by 1 wei due to payable(owner).transfer(1),
    // so the ETH balance of a user other than the sender is not preserved.



    function test_deposit_assets_transfer_others(address Alice) public {
        // Initialization
        address owner = address(123);
        vm.assume(Alice != owner);

        // owner deploys the Bank contract
        vm.prank(owner);
        b = new Bank();
        uint owner_balance_before = address(owner).balance;    // Storing owner's balance

        // Funding Alice
        vm.deal(address(Alice), 1 ether);

        // Alice deposits 2 wei
        vm.prank(address(Alice));
        (bool success,) = address(b).call{value: 2}(abi.encodeWithSignature("deposit()"));
        assert(success);                                       // Ensuring deposit() does not revert

        uint owner_balance_after = address(owner).balance;    // Storing owner's balance
        
        // Owner's balance increases even though it did not call deposit
        // After a non-reverting deposit(), the ETH balance of a user (here, Alice) but the sender is NOT preserved
        assert(owner_balance_before != owner_balance_after);
    }

}