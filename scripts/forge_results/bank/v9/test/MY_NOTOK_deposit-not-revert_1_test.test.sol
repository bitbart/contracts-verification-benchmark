pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

contract Dummy {
    Bank bank;

    constructor(address _bank) payable {
        bank = Bank(_bank);
    }

    function depositToBank() external payable {
        bank.deposit{value: msg.value}();
    }

    function attack(uint256 amount) external {
        bank.withdraw(amount);
    }

    receive() external payable {
        // During withdraw's call to this contract, attempt to call deposit.
        // Because withdraw is executing under nonReentrant, this will revert.
        bank.deposit{value: 0}();
    }
}

contract BankTest is Test {
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        address bank_deployer = address(0xB0B);
        vm.prank(bank_deployer);
        bank = new Bank();
    }

    function test_not_deposit_revert_violation() public {
        
        // --- PoC setup: deploy attacker, deposit 1 ether from it, then trigger attack ---
        Dummy attacker = new Dummy(address(bank));
        vm.deal(address(this), 1 ether);
        attacker.depositToBank{value: 1 ether}(); // credits[attacker] = 1 ether

        address attackerEOA = address(0xDEAD);
        vm.expectRevert(); // withdraw will fail because nested deposit reverts under nonReentrant
        vm.prank(attackerEOA);
        attacker.attack(1 ether);

        // ....
        
        address user = address(0xC0FFEE);
        
        vm.prank(user);
        uint256 msg_value = type(uint256).max;

        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        vm.expectRevert();
        bank.deposit{value: msg_value}();
    }
}