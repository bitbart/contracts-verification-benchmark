pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";


contract Dummy {}


contract BankTest is Test {
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        bank_deployer = address(0xBEEF);
        vm.prank(bank_deployer);
        bank = new Bank();
    }

    function test_not_deposit_revert_violation() public {
        address u = address(0x123456);
        vm.deal(address(this), 0);
        vm.deal(u, 0);

        address user = address(0x123456);
        
        vm.prank(user);
        uint256 msg_value = 1 ether;

        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        vm.expectRevert();
        bank.deposit{value: msg_value}();
    }
}