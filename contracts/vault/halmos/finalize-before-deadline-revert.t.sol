// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import "target/{{VERSION}}.sol";

interface IHalmosVM {
    function assume(bool condition) external;
    function prank(address msgSender) external;
    function deal(address account, uint256 newBalance) external;
    function roll(uint256 blockNumber) external;
}

contract VaultTest {
    IHalmosVM constant vm =
        IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    Vault vault;

    address constant RECOVERY_KEY = address(0x1234);
    address constant OWNER = address(0xAA);
    uint256 constant WAIT_TIME = 10;

    function setUp() public {
        vm.prank(OWNER);
        vault = new Vault(payable(RECOVERY_KEY), WAIT_TIME);
    }

    /// @notice Property: finalize-before-deadline-revert
    function check_finalize_before_deadline_revert(
        address receiver,
        uint256 amount,
        uint256 initialVaultBalance,
        uint256 timeElapsed
    ) public {
        vm.assume(receiver != address(0));
        vm.assume(receiver != address(vault));
        vm.assume(amount <= initialVaultBalance);

        vm.assume(timeElapsed < WAIT_TIME);

        vm.assume(block.number + timeElapsed >= block.number);

        vm.deal(address(vault), initialVaultBalance);

        vm.prank(OWNER);
        try vault.withdraw(receiver, amount) {
        } catch {
            return;
        }

        vm.roll(block.number + timeElapsed);

        vm.prank(OWNER);
        try vault.finalize() {
            assert(false);
        } catch {
            assert(true);
        }
    }
}