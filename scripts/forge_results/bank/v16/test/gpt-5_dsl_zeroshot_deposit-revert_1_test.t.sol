pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

contract Dummy {}

contract BankTest is Test {
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        bank_deployer = address(0xBEEF);
        vm.prank(bank_deployer);
        bank = new Bank();
    }

    function test_deposit_revert_violation() public {
        vm.prank(address(0x1));
        bank.withdraw(1);
        vm.deal(address(0x1), 1);

        address user = address(0x1);
        
        vm.prank(user);
        uint256 msg_value = 1;

        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        assertGt(user_creditsBefore, type(uint256).max - msg_value, "credits plus msg.value do not overflow");
        
        bank.deposit{value: msg_value}(); // does not revert
    }
}