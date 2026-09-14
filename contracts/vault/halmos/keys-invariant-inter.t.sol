
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import "target/{{VERSION}}.sol";

interface IHalmosVM {
    function assume(bool condition) external;
    function prank(address msgSender) external;
    function deal(address account, uint256 newBalance) external;
    function load(address account, bytes32 slot) external view returns (bytes32);
}

contract VaultTest {
    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    Vault vault;

    address constant OWNER = address(0xAA);
    uint256 constant WAIT_TIME = 10;

    /// @notice Property: keys-invariant-inter
    function check_keys_invariant_inter(
        address recoveryKey,
        address randomCaller,
        uint256 initialBalance
    ) public {
        vm.assume(recoveryKey != address(0) && recoveryKey != OWNER);
        vm.assume(randomCaller != address(0));

        vm.prank(OWNER);
        vault = new Vault(payable(recoveryKey), WAIT_TIME);

        vm.deal(address(vault), initialBalance);

        bytes32 initialOwnerSlot = vm.load(address(vault), bytes32(uint256(0)));

        bytes32 initialRecoverySlot = vm.load(address(vault), bytes32(uint256(1)));

        vm.prank(OWNER);
        try vault.withdraw(randomCaller, 1 ether) {} catch {}

        bytes32 currentOwnerSlot = vm.load(address(vault), bytes32(uint256(0)));

        bytes32 currentRecoverySlot = vm.load(address(vault), bytes32(uint256(1)));

        assert(currentOwnerSlot == initialOwnerSlot);
        assert(currentRecoverySlot == initialRecoverySlot);
    }
}

