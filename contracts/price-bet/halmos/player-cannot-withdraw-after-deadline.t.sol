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

    /// @notice Property: player-cannot-withdraw-after-deadline
    function check_player_cannot_withdraw_after_deadline(
        uint256 initialPot,
        uint256 timeout,
        address player,
        uint256 blockJump,
        uint256 exchangeRate,
        uint256 oraclePrice
    ) public {
        vm.assume(player != address(0));

        vm.assume(blockJump >= timeout);

        address owner = address(this);

        uint256 deploymentBlock = block.number;

        Oracle oracle = new Oracle(exchangeRate);
        vm.deal(owner, initialPot);
        PriceBet priceBet = new PriceBet{value: initialPot}(address(oracle), timeout, exchangeRate);

        // Player joins
        vm.deal(player, initialPot);
        vm.prank(player);
        try priceBet.join{value: initialPot}() {} catch {
            return;
        }

        if (blockJump > 0) {
            vm.roll(deploymentBlock + blockJump);
        }

        // Ensure deadline has passed
        vm.assume(block.number >= deploymentBlock + timeout);

        Oracle(address(oracle)).set_exchange_rate(oraclePrice);

        uint256 playerBalanceBefore = player.balance;

        // Player fires timeout()
        vm.prank(player);
        try priceBet.timeout() {} catch {}

        // Player fires win()
        vm.prank(player);
        try priceBet.win() {} catch {}

        // Player fires join()
        vm.deal(player, initialPot);
        vm.prank(player);
        try priceBet.join{value: initialPot}() {} catch {}

        // Property: player balance must not increase
        assert(player.balance <= playerBalanceBefore);
    }
}