// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import "target/{{VERSION}}.sol";

interface IHalmosVM {
    function assume(bool condition) external;
    function prank(address msgSender) external;
    function deal(address account, uint256 newBalance) external;
    function load(address account, bytes32 slot) external view returns (bytes32);
}

contract PriceBetTest {
    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    /// @notice Property: join-player
    function check_join_player(
        uint256 initialPot,
        uint256 timeout,
        uint256 exchangeRate,
        address player
    ) public {
        vm.assume(initialPot > 0);
        vm.assume(timeout > 0);
        vm.assume(player != address(0));

        Oracle oracle = new Oracle(100);

        vm.deal(address(this), initialPot);
        PriceBet priceBet;
        try new PriceBet{value: initialPot}(address(oracle), timeout, exchangeRate) returns (PriceBet deployed) {
            priceBet = deployed;
        } catch {
            return;
        }

        vm.deal(player, initialPot);
        vm.prank(player);

        bool joinSuccess = false;
        try priceBet.join{value: initialPot}() {
            joinSuccess = true;
        } catch {
            return;
        }

        if (joinSuccess) {
            // Read the player storage slot (slot 5)
            bytes32 playerStorage = vm.load(address(priceBet), bytes32(uint256(5)));
            address storedPlayer = address(uint160(uint256(playerStorage)));

            assert(storedPlayer != address(0));
            assert(storedPlayer == player);
        }
    }
}