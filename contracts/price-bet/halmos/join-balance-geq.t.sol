// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import "target/{{VERSION}}.sol";

interface IHalmosVM {
    function assume(bool condition) external;
    function prank(address msgSender) external;
    function deal(address account, uint256 newBalance) external;
}

contract PriceBetTest {
    
    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    /// @notice Property: join-balance-geq
    function check_join_balance_geq(
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
        PriceBet priceBet = new PriceBet{value: initialPot}( address(oracle), timeout, exchangeRate );

        vm.deal(player, initialPot);

        vm.prank(player);
        try priceBet.join{value: initialPot}() {

            assert( address(priceBet).balance >= 2 * initialPot );

        } catch {
            
        }
    }
}