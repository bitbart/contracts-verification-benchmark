

pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

//@FILL HERE <...>

contract BankTest is Test {
    Bank bank;
    address user;

    function test_assets() public {

        //@FILL HERE <...>

        uint256 user_balance_before = address(user).balance;

        address sender = //@FILL HERE <...>;
        vm.prank(sender);

        bytes4 function_selector =  //@FILL HERE <...>;
        uint256 msg_value =  //@FILL HERE <...>;
        bytes memory params =  //@FILL HERE <...>;

        // Dynamically call the function with function_selector selector and passed parameters
        address(bank).call{value: msg_value}(abi.encodeWithSelector(function_selector, params));        
	
        assert(function_selector != bank.deposit.selector || sender != user);

        uint256 user_balance_after = address(user).balance;

        assertLe(user_balance_after, user_balance_before, "user balance did not decrease");
    }
}
