pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

contract C1 {}

contract BankTest is Test {
    address immutable bank_deployer;      // TODO check
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        address bank_deployer = address(0xCAFE);
        vm.prank(bank_deployer);
        bank = new Bank();
    }

    function test_deposit_additivity_violation() public {
        vm.deal(address(0x1234), 10 ether);

        address sender = address(0x1234);
        uint256 snapshot = vm.snapshotState();

        address user = sender;
        
        uint256 n1 = 1 ether;
        uint256 n2 = 2 ether;
        
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