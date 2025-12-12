
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

//@FILL HERE <…>

contract BankTest is Test {
    Bank bank;
    address sender;

    //@FILL HERE <…>

    function test_deposit_additivity_violated() public {
        // Snapshot initial state
        uint256 snapshot = vm.snapshotState();

        uint256 n1 = //@FILL HERE <…>;
        uint256 n2 = //@FILL HERE <…>;
        
        // Perform deposit actions
        vm.prank(sender);
        bank.deposit{value: n1}();
        vm.prank(sender);
        bank.deposit{value: n2}();

        address user = //@FILL HERE <…>;

        // Get the state of the credits mapping before revert
        uint256 creditsBeforeRevert = bank.credits(user);

        // Revert to the snapshot
        vm.revertToState(snapshot);

        // After revert, verify the credits mapping has not changed for the sender
        uint256 creditsAfterRevert = bank.credits(user);

        // Assert that the state is different than what it was before revert 
        assertNotEq(creditsAfterRevert, creditsBeforeRevert, "Credits are equal");
    }
}
