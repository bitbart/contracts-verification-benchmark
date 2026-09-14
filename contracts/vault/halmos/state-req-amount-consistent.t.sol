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

    /// @notice Property: state-req-amount-consistent
    function check_state_req_amount_consistent(
        address recoveryKey,
        address receiver,
        uint256 initialBalance,
        uint256 withdrawAmount,
        bool triggerWithdraw
    ) public {
        vm.assume(recoveryKey != address(0) && recoveryKey != OWNER);
        vm.assume(receiver != address(0));

        vm.prank(OWNER);
        vault = new Vault(payable(recoveryKey), WAIT_TIME);

        vm.deal(address(vault), initialBalance);

        if (triggerWithdraw) {
            vm.prank(OWNER);
            try vault.withdraw(receiver, withdrawAmount) {} catch {}
        }

        // Read the current state from storage.
        // Slot 6 stores the States enum:
        // IDLE = 0, REQ = 1.
        bytes32 stateSlot = vm.load(address(vault), bytes32(uint256(6)));

        uint256 currentState = uint256(stateSlot);

        // Slot 5 stores the amount variable.
        bytes32 amountSlot = vm.load(address(vault), bytes32(uint256(5)));

        uint256 storedAmount = uint256(amountSlot);

        if (currentState == 1) {
            assert(storedAmount <= address(vault).balance);
        }
    }
}