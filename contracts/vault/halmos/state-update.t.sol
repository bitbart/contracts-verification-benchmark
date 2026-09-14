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
    IHalmosVM constant vm =
        IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    Vault vault;

    address constant OWNER = address(0xAA);
    uint256 constant WAIT_TIME = 10;

    /// @notice Property: state-update
    ///      - receive: s -> s for any state s
    ///      - withdraw: IDLE -> REQ
    ///      - finalize: REQ -> IDLE
    ///      - cancel: REQ -> IDLE
    function check_state_update(
        address recoveryKey,
        address receiver,
        uint256 initialBalance
    ) public {
        vm.assume(recoveryKey != address(0));
        vm.assume(recoveryKey != OWNER);

        vm.assume(receiver != address(0));

        vm.prank(OWNER);
        vault = new Vault(payable(recoveryKey), WAIT_TIME);

        vm.deal(address(vault), initialBalance);



        // ------------------------------------------------------------
        // 1. receive: IDLE -> IDLE
        // ------------------------------------------------------------

        bytes32 stateBeforeReceive = vm.load(address(vault), bytes32(uint256(6)));

        // Send Ether to the Vault through the receive() function.
        (bool success,) = address(vault).call{value: 1 wei}("");
        assert(success);

        bytes32 stateAfterReceive = vm.load(address(vault), bytes32(uint256(6)));

        // Receiving Ether must not change the state.
        assert(stateAfterReceive == stateBeforeReceive);



        // ------------------------------------------------------------
        // 2. withdraw: IDLE -> REQ
        // ------------------------------------------------------------

        vm.prank(OWNER);
        vault.withdraw(receiver, 1 ether);

        bytes32 stateAfterWithdraw = vm.load(address(vault), bytes32(uint256(6)));

        // REQ = 1.
        assert(uint256(stateAfterWithdraw) == 1);



        // ------------------------------------------------------------
        // 3. receive: REQ -> REQ
        // ------------------------------------------------------------

        bytes32 stateBeforeReceiveInReq = vm.load(address(vault), bytes32(uint256(6)));

        // Receiving Ether while in REQ must not change the state.
        (success,) = address(vault).call{value: 1 wei}("");
        assert(success);

        bytes32 stateAfterReceiveInReq = vm.load(address(vault), bytes32(uint256(6)));

        // The state must remain REQ.
        assert(stateAfterReceiveInReq == stateBeforeReceiveInReq);



        // ------------------------------------------------------------
        // 4. finalize: REQ -> IDLE
        // ------------------------------------------------------------

        vm.roll(block.number + WAIT_TIME);

        vm.prank(OWNER);
        vault.finalize();

        bytes32 stateAfterFinalize = vm.load(address(vault), bytes32(uint256(6)));

        // IDLE = 0.
        assert(uint256(stateAfterFinalize) == 0);



        // ------------------------------------------------------------
        // 5. withdraw: IDLE -> REQ
        // ------------------------------------------------------------

        vm.prank(OWNER);
        vault.withdraw(receiver, 1 ether);

        bytes32 stateAfterSecondWithdraw = vm.load(address(vault), bytes32(uint256(6)));

        // REQ = 1.
        assert(uint256(stateAfterSecondWithdraw) == 1);



        // ------------------------------------------------------------
        // 6. cancel: REQ -> IDLE
        // ------------------------------------------------------------

        // The recovery key cancels the active withdraw request.
        vm.prank(recoveryKey);
        vault.cancel();

        bytes32 stateAfterCancel = vm.load(address(vault), bytes32(uint256(6)));

        // IDLE = 0.
        assert(uint256(stateAfterCancel) == 0);
    }
}
