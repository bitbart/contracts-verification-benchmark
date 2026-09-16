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

    /// @notice Property: owner-cannot-withdraw-before-deadline
    function check_owner_cannot_withdraw_before_deadline(
        uint256 initialPot,
        uint256 timeout,
        address player,
        uint256 blockJump,
        uint256 exchangeRate,
        uint256 oraclePrice
    ) public {
        vm.assume(player != address(0));
        vm.assume(blockJump < timeout);

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

        Oracle(address(oracle)).set_exchange_rate(oraclePrice);

        uint256 ownerBalanceBefore = owner.balance;

        // TEST 1: owner calls timeout()
        vm.prank(owner);
        try priceBet.timeout() {} catch {}

        // TEST 2: owner calls win()
        vm.prank(owner);
        try priceBet.win() {} catch {}

        // TEST 3: owner calls join()
        vm.deal(owner, initialPot);
        vm.prank(owner);
        try priceBet.join{value: initialPot}() {} catch {}

        assert(owner.balance <= ownerBalanceBefore);
    }
}