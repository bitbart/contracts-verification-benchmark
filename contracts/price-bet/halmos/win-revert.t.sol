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

    /// @notice Property: win-revert
    function check_win_revert(
        uint256 initialPot,
        uint256 timeout,
        address owner,
        address player,
        address caller,
        uint256 blockJump,
        uint256 exchangeRate,
        uint256 oraclePrice
    ) public {
        vm.assume(owner != address(0));
        vm.assume(player != address(0));
        vm.assume(caller != address(0));
        vm.assume(owner != player);
        vm.assume(player != address(this));
        vm.assume(player.code.length == 0);

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

        // 1) deadline has expired 
        // 2) sender is not the player
        // 3) oracle exchange rate is less than the bet exchange rate
        bool deadlineExpired = block.number >= deploymentBlock + timeout;
        bool senderIsNotPlayer = (caller != player);
        bool oracleRateTooLow = (oraclePrice < exchangeRate);

        // If any of these revert conditions are met, win() must revert.
        if (deadlineExpired || senderIsNotPlayer || oracleRateTooLow) {
            vm.prank(caller);
            try priceBet.win() {
                assert(false);
            } catch {
                // Reverted as expected
                assert(true);
            }
        }
    }
}