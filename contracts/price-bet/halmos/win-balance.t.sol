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

    /// @notice Property: win-balance
    function check_win_balance(
        uint256 initialPot,
        uint256 timeout,
        address owner,
        address player,
        uint256 blockJump,
        uint256 exchangeRate,
        uint256 oraclePrice
    ) public {
        vm.assume(owner != address(0));
        vm.assume(player != address(0));
        vm.assume(owner != player);
        vm.assume(player != address(this));        
        vm.assume(blockJump < timeout);
        
        vm.assume(oraclePrice >= exchangeRate);

        uint256 deploymentBlock = block.number;

        Oracle oracle = new Oracle(oraclePrice);
        vm.deal(owner, initialPot);
        
        vm.prank(owner);
        PriceBet priceBet = new PriceBet{value: initialPot}(address(oracle), timeout, exchangeRate);

        vm.deal(player, initialPot);
        vm.prank(player);
        priceBet.join{value: initialPot}();

        if (blockJump > 0) {
            vm.roll(deploymentBlock + blockJump);
        }
        vm.assume(block.number < deploymentBlock + timeout);

        uint256 prev_player_balance = player.balance;
        uint256 prev_contract_balance = address(priceBet).balance;

        // Player calls win 
        vm.prank(player);
        try priceBet.win(){}catch{}

        uint256 post_player_balance = player.balance;
        
        assert(post_player_balance >= prev_player_balance + prev_contract_balance);
        assert(address(priceBet).balance == 0);
    }
}