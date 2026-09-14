// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import "target/{{VERSION}}.sol";

interface IHalmosVM {
    function assume(bool condition) external;
    function prank(address msgSender) external;
    function deal(address account, uint256 newBalance) external;
}

contract VaultTest {
    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    Vault vault;

    address constant OWNER = address(0xAA);
    uint256 constant WAIT_TIME = 10;

    /// @notice Property: cancel-not-revert
    function check_cancel_not_revert(
        address recoveryKey,
        address receiver,
        uint256 initialBalance,
        uint256 withdrawAmount
    ) public {
        vm.assume(recoveryKey != address(0));
        vm.assume(recoveryKey != OWNER);
        vm.assume(receiver != address(0));

        vm.prank(OWNER);
        vault = new Vault(payable(recoveryKey), WAIT_TIME);

        vm.deal(address(vault), initialBalance);

        vm.prank(OWNER);
        vault.withdraw(receiver, withdrawAmount);

        vm.prank(recoveryKey);
        vault.cancel();
    }
}
