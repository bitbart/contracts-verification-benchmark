pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

// File: lib/ReentrancyGuard.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;
abstract contract ReentrancyGuard {
    modifier nonReentrant() virtual {
        _;
    }
}

contract BankTest is Test {
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        address bank_deployer_ = address(0xB0B);
        bank_deployer = bank_deployer_;
        vm.prank(bank_deployer);
        bank = new Bank();
    }

    function test_not_deposit_revert_violation() public {
        // Ensure the chosen user has zero balance
        vm.deal(address(0xCAFE), 0);

        address user = address(0xCAFE);
        
        vm.prank(user);
        uint256 msg_value = 1 ether;

        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        vm.expectRevert();
        bank.deposit{value: msg_value}();
    }
}