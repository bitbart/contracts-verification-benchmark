pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

/* @fill here with type `contract` */
contract Attacker {
    Bank public bank;
    uint256 public onReceiveDeposit;

    constructor(Bank _bank) {
        bank = _bank;
    }

    function setOnReceiveDeposit(uint256 v) external {
        onReceiveDeposit = v;
    }

    receive() external payable {
        if (onReceiveDeposit > 0) {
            bank.deposit{value: onReceiveDeposit}();
        }
    }
}

contract BankTest is Test {       
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        bank_deployer = /* @fill here with type `address` */ address(0x1234);
        vm.prank(bank_deployer);
        bank = new Bank();
    }
    
    function test_assets_dec_onlyif_deposit_violation() public {

        /* @fill here with type `tx_sequence` */
        Attacker attacker = new Attacker(bank);
        vm.deal(address(attacker), 1 ether);
        attacker.setOnReceiveDeposit(1000); // will deposit 1000 wei on receive
        vm.prank(address(attacker));
        bank.deposit{value: 10000}(); // ensure credits >= 32 and fund the bank

        address user = /* @fill here with type `address` */ address(attacker);
        assertNotEq(user, address(bank), "user address equal to bank address");

        uint256 user_balance_before = address(user).balance;

        address sender = /* @fill here with type `address` */ address(attacker);
        vm.prank(sender);

        bytes4 function_selector =  /* @fill here with type `bytes4` */ bank.withdraw.selector;
        uint256 msg_value = /* @fill here with type `uint256` */ 0;
        bytes memory params =  /* @fill here with type `bytes memory` */ bytes("");

        // Dynamically call the function with function_selector selector and passed parameters
        address(bank).call{value: msg_value}(abi.encodeWithSelector(function_selector, params));        
	
        assert(function_selector != bank.deposit.selector || sender != user);

        uint256 user_balance_after = address(user).balance;

        assertLt(user_balance_after, user_balance_before, "user balance did not decrease");
    }
}