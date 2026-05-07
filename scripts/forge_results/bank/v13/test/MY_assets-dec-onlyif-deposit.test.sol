

pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

contract Recipient {
    uint256 public received;
    receive() external payable {
        received += msg.value;
    }
}

contract Attacker {
    address payable public B;
    constructor(address payable _B) payable {
        B = _B;
    }
    receive() external payable {
        (bool ok, ) = payable(B).call{value: 2 ether}("");
        require(ok);
    }
}

contract BankTest is Test {       
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        bank_deployer = vm.addr(1);
        vm.prank(bank_deployer);
        bank = new Bank();
    }
    
    function test_assets_dec_onlyif_deposit_violation() public {

        //uint256[] txs;

        // Deploy recipient and attacker, fund attacker and deposit into Bank
        Recipient b = new Recipient();
        Attacker a = new Attacker(payable(address(b)));
        vm.deal(address(a), 4 ether);
        vm.prank(address(a));
        address(bank).call{value: 2 ether}(abi.encodeWithSelector(bank.deposit.selector));
        address user = address(a);
        assertNotEq(user, address(bank), "user address equal to bank address");

        uint256 user_balance_before = address(user).balance;

        address sender = address(a);
        vm.prank(sender);

        bytes4 function_selector = bank.withdraw.selector;
        uint256 msg_value = 0;
        uint256 params = 1 ether;

        // Dynamically call the function with function_selector selector and passed parameters
        address(bank).call{value: msg_value}(abi.encodeWithSelector(function_selector, params));        
	
        assert(function_selector != bank.deposit.selector || sender != user);

        uint256 user_balance_after = address(user).balance;

        assertLt(user_balance_after, user_balance_before, "user balance did not decrease");
    }
}


