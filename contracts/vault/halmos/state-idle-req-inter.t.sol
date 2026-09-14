// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import "target/{{VERSION}}.sol";

interface IHalmosVM {
    function assume(bool condition) external;
    function prank(address msgSender) external;
    function deal(address account, uint256 newBalance) external;
    function roll(uint256 blockNumber) external;
    function load(address account, bytes32 slot) external view returns (bytes32);
}

contract VaultTest {
    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    Vault vault;

    address constant OWNER = address(0xAA);
    uint256 constant WAIT_TIME = 10;

    /// @notice Property: state-idle-req-inter
    function check_state_idle_req_inter(
        address recoveryKey,
        address receiver,
        uint256 initialBalance,
        bool triggerAction,
        uint256 withdrawAmount
    ) public {
        vm.assume(recoveryKey != address(0) && recoveryKey != OWNER);
        vm.assume(receiver != address(0));

        vm.deal(address(vault), initialBalance);

        vm.prank(OWNER);
        vault = new Vault(payable(recoveryKey), WAIT_TIME);

        if (triggerAction) {
            vm.prank(OWNER);
            try vault.withdraw(receiver, withdrawAmount) {} catch {}
        }

        bytes32 stateSlot = vm.load(address(vault), bytes32(uint256(6)));
        uint256 stateValue = uint256(stateSlot);

        assert(stateValue == 0 || stateValue == 1);
    }
}