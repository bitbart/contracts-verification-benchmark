pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

/* @fill here with type `contract` */
contract Dummy {}

contract BankTest is Test {       
    address immutable bank_deployer;      
    Bank immutable bank;
    address immutable user;
    
    constructor() {
        // deploying a Bank contract
        bank_deployer = /* @fill here with type `address` */ address(0xB0B);
        vm.prank(bank_deployer);
        bank = new Bank();
    }
    
    function test_assets_dec_onlyif_deposit_violation() public {

        /* @fill here with type `tx_sequence` */
        // Fund a depositor and deposit into the Bank to create withdrawable balance
        address depositor = address(0xA11CE);
        vm.deal(depositor, 1 ether);
        vm.prank(depositor);
        bank.deposit{value: 1 ether}();

        // Shadow the immutable user with a local variable for assignment below
        address user;

        user = /* @fill here with type `address` */ address(bank);

        uint256 user_balance_before = address(user).balance;

        address sender = /* @fill here with type `address` */ depositor;
        vm.prank(sender);

        bytes4 function_selector =  /* @fill here with type `bytes4` */ Bank.withdraw.selector;
        uint256 msg_value = /* @fill here with type `uint256` */ 0;
        // Encoding a single bytes parameter; withdraw(uint256) will read the first 32 bytes (0x20) as amount = 32 wei
        bytes memory params =  /* @fill here with type `bytes memory` */ hex"";

        // Dynamically call the function with function_selector selector and passed parameters
        address(bank).call{value: msg_value}(abi.encodeWithSelector(function_selector, params));        
	
        assert(function_selector != bank.deposit.selector || sender != user);

        uint256 user_balance_after = address(user).balance;

        assertLt(user_balance_after, user_balance_before, "user balance did not decrease");
    }
}