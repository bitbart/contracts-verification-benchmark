

pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

// property: after a successful withdraw(amount), the balances of any user but the sender are preserved.

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
    
    
    function test_withdraw_assets_credit_others_violation() public {

        abstract transaction[] txs;


        abstract uint256 amount;
        abstract address sender;
        uint256 credits_slot = uint256(0);
        bytes32 sender_credits_slot = keccak256(abi.encode(sender, credits_slot));
        uint256 sender_creditsBefore = uint256(vm.load(address(bank), sender_credits_slot));

        vm.prank(sender);
        bank.deposit(amount); // should not revert
	
        uint256 sender_creditsAfter = uint256(vm.load(address(bank), sender_credits_slot));

        assertEq(sender_creditsBefore, sender_creditsAfter, "sender credits changed");
    }
}
