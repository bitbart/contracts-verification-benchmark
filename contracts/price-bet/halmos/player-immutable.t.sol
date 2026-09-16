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

contract PriceBetTest {

    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    /// @notice Property: player-immutable
    function check_player_immutable(
        uint256 initialPot,
        uint256 timeout,
        address player1,
        address player2,
        uint256 exchangeRate
    ) public {
        vm.assume(player1 != address(0));
        vm.assume(player2 != address(0));
        vm.assume(player1 != player2);

        address owner = address(this);
        Oracle oracle = new Oracle(exchangeRate);
        vm.deal(owner, initialPot);
        
        PriceBet priceBet;
        try new PriceBet{value: initialPot}(address(oracle), timeout, exchangeRate) returns (PriceBet deployed) {
            priceBet = deployed;
        } catch {
            return;
        }

        // Player 1 joins
        vm.deal(player1, initialPot);
        vm.prank(player1);
        try priceBet.join{value: initialPot}() {} catch {
            return;
        }

        // Read player address from storage slot 5
        bytes32 playerSlotBefore = vm.load(address(priceBet), bytes32(uint256(5)));
        address storedPlayerBefore = address(uint160(uint256(playerSlotBefore)));
        
        vm.assume(storedPlayerBefore == player1);

        // Player 2 attempts to join and overwrite the player
        vm.deal(player2, initialPot);
        vm.prank(player2);
        try priceBet.join{value: initialPot}() {} catch {}

        // Read player address from storage again
        bytes32 playerSlotAfter = vm.load(address(priceBet), bytes32(uint256(5)));
        address storedPlayerAfter = address(uint160(uint256(playerSlotAfter)));

        assert(storedPlayerAfter == storedPlayerBefore);
    }
}