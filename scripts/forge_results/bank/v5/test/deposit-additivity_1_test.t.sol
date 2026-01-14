pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

/* @fill here with type `contract` */
contract Helper {}

contract BankTest is Test {
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        bank_deployer = /* @fill here with type `address` */ address(0xBEEF);
        vm.prank(bank_deployer);
        bank = new Bank();
    }

    function test_deposit_additivity_violated() public {
        address sender = /* @fill here with type `address` */ address(0xAA);
        uint256 snapshot = vm.snapshotState();

        address user = /* @fill here with type `address` */ address(0xAA);
        
        uint256 n1 = /* @fill here with type `uint256` */ 0;
        uint256 n2 = /* @fill here with type `uint256` */ 0;
        
        vm.prank(sender);
        bank.deposit{value: n1}();
        vm.prank(sender);
        bank.deposit{value: n2}();


        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_credits_pathA = uint256(vm.load(address(bank), user_credits_slot));

        vm.revertToState(snapshot);

        vm.prank(sender);
        bank.deposit{value: n1+n2}();

        uint256 user_credits_pathB = uint256(vm.load(address(bank), user_credits_slot));

        assertNotEq(user_credits_pathB, user_credits_pathA, "Credits are equal");
    }
}