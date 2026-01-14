

pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

// "exists-unique-asset-change": "after a non-reverting `deposit` or `withdraw` transaction to the Bank contract, the ETH balance of exactly one account (except the contract's) have changed",

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
    
    function test_exists_at_most_one_asset_change_violation() public {

        /* @fill here with type `tx_sequence` */

        address user1 = /* @fill here with type `address` */;
        address user2 = /* @fill here with type `address` */;

        assertNotEq(user1, address(bank), "user1 address equal to bank address");
        assertNotEq(user2, address(bank), "user2 address equal to bank address");
        assertNotEq(user1, user2, "user2 address equal to user1 address");

        uint256 user1_balance_before = address(user1).balance;
        uint256 user2_balance_before = address(user2).balance;

        address sender = /* @fill here with type `address` */;
        vm.prank(sender);

        bytes4 function_selector =  /* @fill here with type `bytes4` */;
        uint256 msg_value = /* @fill here with type `uint256` */;
        bytes memory params =  /* @fill here with type `bytes memory` */;

        // Dynamically call the function with function_selector selector and passed parameters
        address(bank).call{value: msg_value}(abi.encodeWithSelector(function_selector, params));        
	
        assert(function_selector == bank.deposit.selector || function_selector == bank.withdraw.selector);

        uint256 user1_balance_after = address(user1).balance;
        uint256 user2_balance_after = address(user2).balance;

        assert(user1_balance_after != user1_balance_before && user2_balance_after != user2_balance_before );
    }
}

