
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";


/* @fill here with type `contract` */


contract BankTest is Test {
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        bank_deployer = /* @fill here with type `address` */;
        vm.prank(bank_deployer);
        bank = new Bank();
    }

    function test_not_deposit_revert_violation() public {
        /* @fill here with type `tx_sequence` */

        address user = /* @fill here with type `address` */;
        
        vm.prank(user);
        uint256 msg_value =  /* @fill here with type `uint256` */;

        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        vm.expectRevert();
        bank.deposit{value: msg_value}();
    }
}

