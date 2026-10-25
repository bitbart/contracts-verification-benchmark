// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import {Test} from "forge-std/Test.sol";
import {Bank} from "versions/Bank_v4.sol";

// Contract user (userContract1 = 0xaaaa0005 in the counterexample).
contract User {}

// tx1: deposit()  p_value = 0x100000000000000000000000000000000
// The bug: credits[msg.sender] += msg.value - 1
contract PoC_DepositAssetsCredit_v4 is Test {

    Bank bank;
    User user;

    function setUp() public {
        bank = new Bank();
        user = new User();
    }

    function test_poc_deposit_assets_credit() public {
        address sender = address(user);
        uint256 value = 0x100000000000000000000000000000000;

        vm.deal(sender, value);

        bytes32 slot = keccak256(abi.encode(sender, uint256(0)));
        uint256 creditBefore = uint256(vm.load(address(bank), slot));

        vm.prank(sender);
        (bool ok,) = address(bank).call{value: value}(abi.encodeWithSignature("deposit()"));
        assertTrue(ok, "deposit() reverted unexpectedly");

        uint256 creditAfter = uint256(vm.load(address(bank), slot));

        assertNotEq(creditAfter - creditBefore, value, "deposit-assets-credit holds: counterexample not reproduced");
    }
}
