// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import {Test} from "forge-std/Test.sol";
import {Bank} from "versions/Bank_v1.sol";

// Contract user A (userContract1 = 0xaaaa0005 in the counterexample).
// Its receive() implements only the behaviour chosen by Halmos:
//   reentryValue == 0 => receive_choice = 0 (accepts, does nothing)
//   reentryValue >  0 => receive_choice = 2, receive_peer_acts = false (A itself calls deposit)
contract A {
    Bank immutable bank;
    uint256 public reentryValue;

    constructor(Bank _bank) { bank = _bank; }

    function setReentry(uint256 v) external { reentryValue = v; }

    receive() external payable {
        if (reentryValue > 0) {
            uint256 v = reentryValue;
            reentryValue = 0; // reacts at most once, like `reacted` in BankUser
            bank.deposit{value: v}();
        }
    }
}

// halmos_A_address = 0xaaaa0005 (A is userContract1)
// tx1: deposit()                                    p_value  = 0x100000000000000000000000000000000
// tx2: withdraw(0xffffffffffffffffffffffff80000000)  receive_choice = 0
// tx3: withdraw(1)                                  receive_choice = 2, receive_call_value = 0x180000001
// tx.origin = 0x8000...0000 
// The bug: the low-level call in `withdraw` gives control to msg.sender,
// whose receive() deposits more than it received
contract PoC_AssetsDecOnlyifDeposit_v1 is Test {

    Bank bank;
    A a;

    function setUp() public {
        bank = new Bank();
        a = new A(bank);
    }

    function test_poc_assets_dec_onlyif_deposit() public {
        uint256 value = 0x100000000000000000000000000000000;
        vm.deal(address(a), value);
        vm.prank(address(a));
        bank.deposit{value: value}();

        // tx2: A withdraws, its receive() does nothing
        vm.prank(address(a));
        bank.withdraw(0xffffffffffffffffffffffff80000000);

        // tx3: A withdraws 1 wei, its receive() re-enters with deposit(0x180000001)
        a.setReentry(0x180000001);
        uint256 balanceBefore = address(a).balance;

        vm.prank(address(a));
        bank.withdraw(1);

        uint256 balanceAfter = address(a).balance;

        // property: if A's balance decreased, the tx must be a `deposit` by A
        // on v1 this is violated: A's balance decreased, but the tx was a `withdraw`
        assertLt(balanceAfter, balanceBefore, "assets-dec-onlyif-deposit holds: counterexample not reproduced");
    }
}
