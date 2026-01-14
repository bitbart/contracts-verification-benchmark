pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

/* @fill here with type `contract` */
contract Attacker {
    Bank public bank;
    constructor(Bank _bank) {
        bank = _bank;
    }
    receive() external payable {
        // Re-enter and deposit more than received to ensure net balance decrease
        bank.deposit{value: msg.value + 1}();
    }
}

contract BankTest is Test {       
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        bank_deployer = /* @fill here with type `address` */ address(0xBEEF);
        vm.prank(bank_deployer);
        bank = new Bank();
    }
    
    function test_assets_dec_onlyif_deposit_violation() public {

        /* @fill here with type `tx_sequence` */
        Attacker attacker = new Attacker(bank);
        // Fund this test contract to perform an initial deposit crediting the attacker
        vm.deal(address(this), 1000);
        vm.prank(address(attacker));
        bank.deposit{value: 100}(); // credits[attacker] = 99, bank balance = 99
        // Give attacker 1 wei so it can deposit more than it receives during reentrancy
        vm.deal(address(attacker), 1);

        address user = /* @fill here with type `address` */ address(attacker);
        assertNotEq(user, address(bank), "user address equal to bank address");

        uint256 user_balance_before = address(user).balance;

        address sender = /* @fill here with type `address` */ address(attacker);
        vm.prank(sender);

        bytes4 function_selector =  /* @fill here with type `bytes4` */ bank.withdraw.selector;
        uint256 msg_value = /* @fill here with type `uint256` */ 0;
        bytes memory params =  /* @fill here with type `bytes memory` */ bytes("");

        // Dynamically call the function with function_selector selector and passed parameters
        // For withdraw(uint256), passing a bytes dynamic arg results in the first word = 0x20, i.e., amount = 32 wei
        address(bank).call{value: msg_value}(abi.encodeWithSelector(function_selector, params));        
	
        assert(function_selector != bank.deposit.selector || sender != user);

        uint256 user_balance_after = address(user).balance;

        assertLt(user_balance_after, user_balance_before, "user balance did not decrease");
    }
}