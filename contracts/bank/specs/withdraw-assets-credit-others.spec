

pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

// property: after a successful withdraw(amount), the balances of any user but the sender are preserved.

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
    
    
    function test_withdraw_assets_credit_others_violation() public {

        /* @fill here with type `tx_sequence` */

	    address user = /* @fill here with type `address` */;
        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        uint256 amount = /* @fill here with type `uint256` */;
        address sender = /* @fill here with type `address` */;
        vm.prank(sender);
        bank.withdraw(amount); // should not revert
	
        uint256 user_creditsAfter = uint256(vm.load(address(bank), user_credits_slot));

        assertNotEq(sender, user, "user equal to sender");

        assertNotEq(user_creditsBefore, user_creditsAfter, "user credits did not change");
    }
}
