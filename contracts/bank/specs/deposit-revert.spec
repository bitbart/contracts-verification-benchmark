
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";


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

    function test_deposit_revert_violation() public {
        abstract transaction[] txs;

        abstract address user;
        
        vm.prank(user);
        abstract uint256 msg_value;

        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        assertGt(user_creditsBefore, type(uint256).max - msg_value, "credits plus msg.value do not overflow");
        
        bank.deposit{value: msg_value}(); // should not revert
    }
}

