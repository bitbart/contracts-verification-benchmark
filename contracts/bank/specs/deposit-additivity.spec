
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

//@FILL HERE <…>

contract BankTest is Test {
    Bank bank;
    address sender;

    //@FILL HERE <…>

    function test_deposit_additivity_violated() public {
        uint256 snapshot = vm.snapshotState();

        address user = //@FILL HERE <…>;
        
        uint256 n1 = //@FILL HERE <…>;
        uint256 n2 = //@FILL HERE <…>;
        
        vm.prank(sender);
        bank.deposit{value: n1}();
        vm.prank(sender);
        bank.deposit{value: n2}();


        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        vm.revertToState(snapshot);

        vm.prank(sender);
        bank.deposit{value: n1+n2}();

        uint256 user_creditsAfter = uint256(vm.load(address(bank), user_credits_slot));

        assertNotEq(user_creditsAfter, user_creditsBefore, "Credits are equal");
    }
}
