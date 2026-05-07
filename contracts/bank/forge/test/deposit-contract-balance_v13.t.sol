// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v13.sol";


contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // deposit-contract-balance:
    // after a non-reverting deposit(), the ETH balance of the contract is increased by msg.value.

    // PoC produced by GPT-5:
    // Let the contract’s initial ETH balance be 0 and the owner be an EOA so transfer succeeds.
    // A user calls deposit() with msg.value = 2 wei.
    // The function transfers 1 wei to owner and credits 1 wei to the user.
    // The transaction does not revert.
    // Final contract balance = 1 wei, which is an increase of 1 wei, not msg.value (2 wei).


    function test_deposit_contract_balance() public {
        // Initialization
        address owner = address(123);
        address user = address(456);
        
        // owner deploys the Bank contract
        vm.prank(owner);
        b = new Bank();
        assert(address(b).balance == 0);                       // Bank's initial ETH balance is 0

        // Funding user
        vm.deal(address(user), 1 ether);

        uint Bank_balance_before = address(b).balance;        // Balance of Bank before the Trxn

        // user deposits 2 wei
        vm.prank(address(user));
        uint deposit_value = 2;
        (bool success,) = address(b).call{value: deposit_value}(abi.encodeWithSignature("deposit()"));
        assert(success);                                       // Ensuring deposit() does not revert

        uint Bank_balance_after = address(b).balance;        // Balance of Bank after the Trxn


        // Bank's contract balance increases by 1 wei (when it should increase by 2 wei)
        // after a non-reverting deposit(), the ETH balance of Bank is NOT increased by msg.value
        assert(Bank_balance_after != Bank_balance_before + deposit_value);
    }

}