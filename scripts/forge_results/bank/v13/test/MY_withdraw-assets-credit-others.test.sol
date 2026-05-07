

pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

// property: after a successful withdraw(amount), the balances of any user but the sender are preserved.

contract Helper {
    Bank public bank;
    constructor(Bank _bank) { bank = _bank; }
    function forwardDeposit() external payable {
        bank.deposit{value: msg.value}();
    }
}

contract Attacker {
    Bank public bank;
    Helper public helper;
    constructor(Bank _bank, Helper _helper) payable { bank = _bank; helper = _helper; }
    receive() external payable {
        (bool success,) = address(helper).call{value: msg.value}(abi.encodeWithSignature("forwardDeposit()"));
        require(success);
    }
    function attackDeposit() external payable {
        bank.deposit{value: msg.value}();
    }
    function doWithdraw(uint amount) external {
        bank.withdraw(amount);
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

        Helper helper = new Helper(bank);
        Attacker attacker = new Attacker(bank, helper);
        vm.deal(address(this), 10);
        attacker.attackDeposit{value: 3}();

        address user = address(helper);
        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        uint256 amount = 2;
        address sender = address(attacker);
        vm.prank(sender);
        bank.withdraw(amount); // should not revert
	
        uint256 user_creditsAfter = uint256(vm.load(address(bank), user_credits_slot));

        assertNotEq(sender, user, "user equal to sender");

        assertNotEq(user_creditsBefore, user_creditsAfter, "user credits did not change");
    }
}
