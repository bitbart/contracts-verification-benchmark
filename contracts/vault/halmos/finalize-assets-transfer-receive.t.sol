// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import "target/{{VERSION}}.sol";

interface IHalmosVM {
    function assume(bool condition) external;
    function prank(address msgSender) external;
    function deal(address account, uint256 newBalance) external;
    function roll(uint256 blockNumber) external;
}

// A simple receiver contract that accepts all incoming ETH
contract HonestReceiver {
    receive() external payable {}
}

contract VaultTest {
    IHalmosVM constant vm =
        IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    Vault vault;
    HonestReceiver receiver;

    address constant OWNER = address(0xAA);
    uint256 constant WAIT_TIME = 10;

    /// @notice Property: finalize-assets-transfer-receive
    function check_finalize_assets_transfer_receive(
        address recoveryKey,
        uint256 initialBalance,
        uint256 withdrawAmount
    ) public {
        vm.assume(recoveryKey != address(0) && recoveryKey != OWNER);

        receiver = new HonestReceiver();

        vm.prank(OWNER);
        vault = new Vault(payable(recoveryKey), WAIT_TIME);

        vm.deal(address(vault), initialBalance);
        vm.prank(OWNER);
        vault.withdraw(address(receiver), withdrawAmount);

        vm.roll(block.number + WAIT_TIME);

        uint256 vaultBalanceBefore = address(vault).balance;
        uint256 receiverBalanceBefore = address(receiver).balance;

        vm.prank(OWNER);
        vault.finalize();

        assert(address(receiver).balance == receiverBalanceBefore + withdrawAmount);
        assert(address(vault).balance == vaultBalanceBefore - withdrawAmount);
    }
}