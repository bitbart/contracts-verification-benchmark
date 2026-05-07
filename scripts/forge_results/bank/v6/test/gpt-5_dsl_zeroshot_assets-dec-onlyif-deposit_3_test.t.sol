pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

// Replacement for `abstract contracts[] cs;`
contract Dummy {}

contract BankTest is Test {
    address immutable bank_deployer;
    Bank immutable bank;

    // On receiving ETH, forward the entire balance away to reduce this contract's balance
    receive() external payable {
        payable(address(0xDEAD)).call{value: address(this).balance}("");
    }

    constructor() {
        // Replacement for `abstract address bank_deployer;`
        address bank_deployer = address(0xB0B);
        vm.prank(bank_deployer);
        bank = new Bank();
    }
    
    function test_assets_dec_onlyif_deposit_violation() public {

        // Replacement for `abstract transaction[] txs;`
        // Setup: fund this contract, deposit 32 wei as this contract (crediting it),
        // and add 1 wei liquidity from another address so withdraw can pay amount+1.
        vm.deal(address(this), 100 wei);
        bank.deposit{value: 32 wei}();
        vm.deal(address(0xA11CE), 1 wei);
        vm.prank(address(0xA11CE));
        bank.deposit{value: 1 wei}();

        // Replacement for `abstract address user;`
        address user = address(this);
        assertNotEq(user, address(bank), "user address equal to bank address");

        uint256 user_balance_before = address(user).balance;

        // Replacement for `abstract address sender;`
        address sender = address(this);
        vm.prank(sender);

        // Replacement for `abstract bytes4 function_selector;`
        bytes4 function_selector = Bank.withdraw.selector;
        // Replacement for `abstract uint256 msg_value;`
        uint256 msg_value = 0;
        // Replacement for `abstract bytes memory params;`
        // Using empty bytes so withdraw(uint256) decodes amount = 32 (ABI offset 0x20).
        bytes memory params = hex"";

        // Dynamically call the function with function_selector selector and passed parameters
        address(bank).call{value: msg_value}(abi.encodeWithSelector(function_selector, params));        
	
        assert(function_selector != bank.deposit.selector || sender != user);

        uint256 user_balance_after = address(user).balance;

        assertLt(user_balance_after, user_balance_before, "user balance did not decrease");
    }
}