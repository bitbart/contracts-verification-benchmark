
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

    /// @notice Property: keys-distinct
    function check_keys_distinct(
        address recoveryKey,
        uint256 waitTime
    ) public {
        vm.assume(recoveryKey != address(0));

        vm.prank(OWNER);
        vault = new Vault(payable(recoveryKey), waitTime);

        // - Slot 0: owner address
        // - Slot 1: recovery address
        bytes32 ownerSlot = vm.load(address(vault), bytes32(uint256(0)));
        bytes32 recoverySlot = vm.load(address(vault), bytes32(uint256(1)));

        address vaultOwner = address(uint160(uint256(ownerSlot)));
        address vaultRecovery = address(uint160(uint256(recoverySlot)));

        assert(vaultOwner != vaultRecovery);
    }
}
