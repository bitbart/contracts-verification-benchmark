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

    /// @notice Property: timeout-balance
    function check_timeout_balance(
        uint256 initialPot,
        uint256 timeout,
        address owner,
        address player,
        uint256 blockJump,
        uint256 exchangeRate
    ) public {
        vm.assume(owner != address(0));
        vm.assume(player != address(0));
        vm.assume(player != owner);
        vm.assume(blockJump >= timeout);

        uint256 deploymentBlock = block.number;

        Oracle oracle = new Oracle(exchangeRate);
        
        vm.deal(owner, initialPot);
        vm.prank(owner);
        PriceBet priceBet = new PriceBet{value: initialPot}(address(oracle), timeout, exchangeRate);

        vm.deal(player, initialPot);
        vm.prank(player);
        priceBet.join{value: initialPot}();

        vm.roll(deploymentBlock + blockJump);
        vm.assume(block.number >= deploymentBlock + timeout);

        uint256 contractBalanceBefore = address(priceBet).balance;
        uint256 ownerBalanceBefore = address(owner).balance;

        vm.prank(owner);
        priceBet.timeout();

        // Property check
        assert(address(owner).balance == ownerBalanceBefore + contractBalanceBefore);
    }
}