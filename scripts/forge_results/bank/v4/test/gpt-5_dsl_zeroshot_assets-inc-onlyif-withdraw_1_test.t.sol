pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../Bank.sol";

// Forwarder that forwards any received ETH to a beneficiary without reverting
contract Forwarder {
    address payable public beneficiary;
    constructor(address payable _b) {
        beneficiary = _b;
    }
    receive() external payable {
        // do not revert on failure
        beneficiary.call{value: msg.value}("");
    }
    fallback() external payable {
        beneficiary.call{value: msg.value}("");
    }
}

contract BankTest is Test {       
    address immutable bank_deployer;      
    Bank immutable bank;
    
    constructor() {
        // deploying a Bank contract
        address bank_deployer = address(0xBEEF);
        vm.prank(bank_deployer);
        bank = new Bank();
    }
    
    function test_assets_dec_onlyif_deposit_violation() public {

        // 1) Deploy a Forwarder at a deterministic address using CREATE2 with a fixed beneficiary
        new Forwarder{salt: bytes32(uint256(123))}(payable(address(0xB0B)));
        // 2) Fund the Forwarder so it can deposit into Bank
        vm.deal(
            address(uint160(uint(keccak256(
                abi.encodePacked(
                    bytes1(0xff),
                    address(this),
                    bytes32(uint256(123)),
                    keccak256(abi.encodePacked(type(Forwarder).creationCode, abi.encode(payable(address(0xB0B)))))
                )
            )))),
            33
        );
        // 3) Deposit 33 wei from the Forwarder so its Bank credit becomes 32
        vm.prank(
            address(uint160(uint(keccak256(
                abi.encodePacked(
                    bytes1(0xff),
                    address(this),
                    bytes32(uint256(123)),
                    keccak256(abi.encodePacked(type(Forwarder).creationCode, abi.encode(payable(address(0xB0B)))))
                )
            ))))
        );
        bank.deposit{value: 33}();

        address user = address(0xB0B);
        assertNotEq(user, address(bank), "user address equal to bank address");

        uint256 user_balance_before = address(user).balance;

        address sender = address(uint160(uint(keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                bytes32(uint256(123)),
                keccak256(abi.encodePacked(type(Forwarder).creationCode, abi.encode(payable(user))))
            )
        ))));
        vm.prank(sender);

        // Call withdraw via low-level call with a single bytes parameter;
        // the callee decodes it as uint amount = 32 (0x20)
        bytes4 function_selector = bank.withdraw.selector;
        uint256 msg_value = 0;
        bytes memory params = hex"";

        // Dynamically call the function with function_selector selector and passed parameters
        address(bank).call{value: msg_value}(abi.encodeWithSelector(function_selector, params));        
	
        assert(function_selector != bank.withdraw.selector || sender != user);

        uint256 user_balance_after = address(user).balance;

        assertGt(user_balance_after, user_balance_before, "user balance did not increase");
    }
}