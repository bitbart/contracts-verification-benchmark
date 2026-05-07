pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

// Concretize abstract contracts[] cs;
contract Dummy {}

contract BankTest is Test {       
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        // Concretize abstract address bank_deployer;
        bank_deployer = address(0xBEEF);
        vm.prank(bank_deployer);
        bank = new Bank();
    }
    
    function test_assets_dec_onlyif_deposit_violation() public {

        // Concretize abstract transaction[] txs;
        vm.deal(address(0xCAFE), 1 ether);

        // Concretize abstract address user;
        address user = address(0xBEEF);
        assertNotEq(user, address(bank), "user address equal to bank address");

        uint256 user_balance_before = address(user).balance;

        // Concretize abstract address sender;
        address sender = address(0xCAFE);
        vm.prank(sender);

        // Concretize abstract bytes4 function_selector;
        bytes4 function_selector = bank.deposit.selector;
        // Concretize abstract uint256 msg_value;
        uint256 msg_value = 2;
        // Concretize abstract bytes memory params;
        bytes memory params = "";

        // Dynamically call the function with function_selector selector and passed parameters
        address(bank).call{value: msg_value}(abi.encodeWithSelector(function_selector, params));        
	
        assert(function_selector != bank.withdraw.selector || sender != user);

        uint256 user_balance_after = address(user).balance;

        assertGt(user_balance_after, user_balance_before, "user balance did not increase");
    }
}