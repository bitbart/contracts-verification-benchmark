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
    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    Vault vault;

    address constant RECOVERY_KEY = address(0x1234);
    address constant OWNER = address(0xAA);
    uint256 constant WAIT_TIME = 10;

    function setUp() public {
        vm.prank(OWNER);
        vault = new Vault(payable(RECOVERY_KEY), WAIT_TIME);
    }

    /// @notice Property: finalize-revert
    function check_finalize_revert(
        address caller,
        bool createRequest,
        bool waitElapsed,
        uint256 initialVaultBalance
    ) public {
        vm.assume(caller != address(0));
        vm.assume(caller != address(vault));
        vm.assume(caller != address(vm));

        vm.assume(initialVaultBalance >= 1 ether);

        vm.deal(address(vault), initialVaultBalance);

        bool requestCreated = false;

        if (createRequest) {
            vm.prank(OWNER);

            try vault.withdraw(address(0x999), 1 ether) {
                requestCreated = true;
            } catch {
                requestCreated = false;
            }
        }

        if (requestCreated && waitElapsed) {
            vm.roll(block.number + WAIT_TIME);
        }

        bool shouldSucceed = caller == OWNER && requestCreated && waitElapsed;

        vm.prank(caller);

        try vault.finalize() {
            assert(shouldSucceed);
        } catch {
            assert(!shouldSucceed);
        }
    }
}