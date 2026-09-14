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

    address constant RECOVERY_KEY = address(0x1234);
    uint256 constant WAIT_TIME = 1 days;

    function setUp() public {
        vault = new Vault(payable(RECOVERY_KEY), WAIT_TIME);
    }

    /// @notice Property: cancel-revert
    function check_cancel_revert(
        address caller,
        bool inReqState
    ) public {
        vm.assume(caller != address(0));
        vm.assume(caller != address(vault));
        vm.assume(caller != address(vm));

        if (inReqState) {
            vm.deal(address(vault), 10 ether);
            try vault.withdraw(address(0x999), 1 ether) {} catch {}
        }

        vm.prank(caller);
        try vault.cancel() {
            
            bool isRecoveryKey = (caller == RECOVERY_KEY);

            assert(inReqState && isRecoveryKey);
        } catch {
            assert(true);
        }
    }
}