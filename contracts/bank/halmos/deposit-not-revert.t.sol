// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import "target/{{VERSION}}.sol";

interface IHalmosVM {
    function assume(bool condition) external;
    function prank(address msgSender) external;
    function deal(address account, uint256 newBalance) external;
}

contract BankTest {
    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    Bank bank;

    function setUp() public {
        {{CONSTRUCTOR_SETUP}};
    }

    /// @notice Property: deposit-not-revert
    function check_deposit_not_revert(
        address caller,
        uint256 depositAmount
    ) public {
        vm.assume(caller != address(0));
        vm.assume(caller != address(bank));
        vm.assume(caller != address(vm));

        vm.assume(depositAmount <= 1000 ether);
        vm.deal(caller, 2000 ether);

        // Deposit
        vm.prank(caller);
        bank.deposit{value: depositAmount}();
    }
}