
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";


//@FILL HERE <…>


contract BankTest is Test {
    Bank bank;
    address user;

    function test_depositDoesNotRevert() public {
        //@FILL HERE <…>
        
        vm.prank(user);
        uint256 msg_value =  //@FILL HERE <…>;

        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        assertGt(user_creditsBefore, type(uint256).max - msg_value, "credits plus msg.value do not overflow");
        
        bank.deposit{value: msg_value}(); // should not revert
    }
}

