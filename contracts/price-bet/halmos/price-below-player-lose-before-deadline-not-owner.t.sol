// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import "target/{{VERSION}}.sol";

interface IHalmosVM {
    function assume(bool condition) external;
    function prank(address msgSender) external;
    function deal(address account, uint256 newBalance) external;
    function roll(uint256 blockNumber) external;
}

contract PriceBetTest {

    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    /// @notice Property: price-below-player-lose-before-deadline-not-owner
    function check_price_below_player_lose_before_deadline_not_owner(
        uint256 initialPot,
        uint256 timeout,
        address owner,
        address player,
        uint256 blockJump,
        uint256 exchangeRate,
        uint256 oraclePrice,
        bool callTimeout
    ) public {
        vm.assume(owner != address(0));
        vm.assume(player != address(0));
        vm.assume(owner != player);
        vm.assume(player.code.length == 0);

        // Property conditions:
        // 1) Oracle exchange rate is below the target exchange rate
        vm.assume(oraclePrice < exchangeRate);
        // 2) Before the deadline
        vm.assume(blockJump < timeout);

        uint256 deploymentBlock = block.number;

        Oracle oracle = new Oracle(oraclePrice);
        vm.deal(owner, initialPot);
        vm.prank(owner);
        PriceBet priceBet = new PriceBet{value: initialPot}(address(oracle), timeout, exchangeRate);

        // Player joins 
        vm.deal(player, initialPot);
        vm.prank(player);
        priceBet.join{value: initialPot}();

        if (blockJump > 0) {
            vm.roll(deploymentBlock + blockJump);
        }
        vm.assume(block.number < deploymentBlock + timeout);

        // Record player balance before the transaction
        uint256 balanceBefore = player.balance;

        vm.prank(player);
        if (callTimeout) {
            try priceBet.timeout() {
            // Transaction must revert before the deadline; if it succeeds, the property fails 
                assert(false);
            } catch {
                // Reverted as expected
                assert(player.balance <= balanceBefore);
            }
        } else {
            try priceBet.win() {
            // Transaction must revert due to low oracle price; if it succeeds, the property fails 
                assert(false);
            } catch {
                // Reverted as expected
                assert(player.balance <= balanceBefore);
            }
        }
    }
}