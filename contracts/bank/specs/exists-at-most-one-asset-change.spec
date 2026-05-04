

pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

// "exists-unique-asset-change": "after a non-reverting `deposit` or `withdraw` transaction to the Bank contract, the ETH balance of exactly one account (except the contract's) have changed",

abstract contracts[] cs;

contract BankTest is Test {       
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        abstract address bank_deployer;
        vm.prank(bank_deployer);
        bank = new Bank();
    }
    
    function test_exists_at_most_one_asset_change_violation() public {

        abstract transaction[] txs;

        abstract address user1;
        abstract address user2;

        assertNotEq(user1, address(bank), "user1 address equal to bank address");
        assertNotEq(user2, address(bank), "user2 address equal to bank address");
        assertNotEq(user1, user2, "user2 address equal to user1 address");

        uint256 user1_balance_before = address(user1).balance;
        uint256 user2_balance_before = address(user2).balance;

        abstract address sender;
        vm.prank(sender);

        abstract bytes4 function_selector;
        abstract uint256 msg_value;
        abstract bytes memory params;

        // Dynamically call the function with function_selector selector and passed parameters
        address(bank).call{value: msg_value}(abi.encodeWithSelector(function_selector, params));        
	
        assert(function_selector == bank.deposit.selector || function_selector == bank.withdraw.selector);

        uint256 user1_balance_after = address(user1).balance;
        uint256 user2_balance_after = address(user2).balance;

        assert(user1_balance_after != user1_balance_before && user2_balance_after != user2_balance_before );
    }
}

