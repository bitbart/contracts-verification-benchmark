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

    /// @notice Property: only-owner-or-player-receive
    function check_only_owner_or_player_receive(
        uint256 initialPot,
        uint256 timeout,
        uint256 exchangeRate,
        address player,
        address randomAddress,
        uint256 blockJump,
        uint256 oraclePrice
    ) public {
        vm.assume(initialPot > 0);
        vm.assume(timeout > 0);
        vm.assume(exchangeRate > 0);
        vm.assume(player != address(0));
        vm.assume(randomAddress != address(0));
        vm.assume(randomAddress != player);
        vm.assume(oraclePrice >= exchangeRate);

        address owner = address(this);
        uint256 deploymentBlock = block.number;

        Oracle oracle = new Oracle(exchangeRate);
        vm.deal(owner, initialPot);
        
        PriceBet priceBet;
        try new PriceBet{value: initialPot}(address(oracle), timeout, exchangeRate) returns (PriceBet deployed) {
            priceBet = deployed;
        } catch {
            return;
        }

        // Player join
        vm.deal(player, initialPot);
        try priceBet.join{value: initialPot}() {} catch {
            return;
        }

        if (blockJump > 0) {
            vm.roll(deploymentBlock + blockJump);
        }

        Oracle(address(oracle)).set_exchange_rate(oraclePrice);
        
        // TEST 1: Verify that a random address cannot receive ETH via win()
        uint256 randomBalanceBefore = randomAddress.balance;
        
        vm.prank(randomAddress);
        try priceBet.win() {} catch {}
        
        // Verify that randomAddress did not receive ETH
        if (randomAddress != owner && randomAddress != player && randomAddress != address(priceBet)) {
            assert(randomAddress.balance == randomBalanceBefore);
        }
        
        // TEST 2: Verify that the player can receive ETH (positive property)
        uint256 playerBalanceBefore = player.balance;
        uint256 contractBalanceBefore = address(priceBet).balance;
        
        vm.prank(player);
        try priceBet.win() {} catch {}
        
        // Verify that the player received ETH (if they won)
        if (oraclePrice >= exchangeRate && block.number < deploymentBlock + timeout) {
            assert(player.balance > playerBalanceBefore);
            assert(address(priceBet).balance < contractBalanceBefore);
        }
        
        // TEST 3: Verify that a random address cannot receive ETH via timeout()
        uint256 randomBalanceBeforeTimeout = randomAddress.balance;
        
        vm.prank(randomAddress);
        try priceBet.timeout() {} catch {}
        
        if (randomAddress != owner && randomAddress != player && randomAddress != address(priceBet)) {
            assert(randomAddress.balance == randomBalanceBeforeTimeout);
        }
        
        // TEST 4: Verify that the owner can receive ETH via timeout()
        uint256 deadline = deploymentBlock + timeout;
        if (block.number < deadline) {
            vm.roll(deadline + 1);
        }
        
        uint256 ownerBalanceBefore = owner.balance;
        uint256 contractBalanceBeforeTimeout = address(priceBet).balance;
        
        vm.prank(randomAddress);
        try priceBet.timeout() {} catch {}
        
        // Verify that the owner received ETH
        if (block.number >= deadline) {
            assert(owner.balance > ownerBalanceBefore);
            assert(address(priceBet).balance < contractBalanceBeforeTimeout);
        }
    }
}