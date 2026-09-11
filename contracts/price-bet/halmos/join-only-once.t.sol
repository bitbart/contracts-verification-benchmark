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

    /// @notice Property: join-only-once
    function check_join_only_once(
        uint256 initialPot,
        uint256 timeout,
        uint256 exchangeRate,
        address player1,
        address player2,
        uint256 playerDeposit
    ) public {
        vm.assume(initialPot > 0);
        vm.assume(playerDeposit >= initialPot);
        vm.assume(timeout > 0);
        vm.assume(player1 != address(0));
        vm.assume(player2 != address(0));
        vm.assume(player1 != player2);

        Oracle oracle = new Oracle(100);

        vm.deal(address(this), initialPot);
        PriceBet priceBet;
        try new PriceBet{value: initialPot}(address(oracle), timeout, exchangeRate) returns (PriceBet deployed) {
            priceBet = deployed;
        } catch {
            return;
        }

        vm.deal(player1, initialPot);
        vm.prank(player1);
        
        bool firstJoinSuccess = false;
        try priceBet.join{value: initialPot}() {
            firstJoinSuccess = true;
        } catch {
            return;
        }

        // If the first join succeeded, a second join MUST revert
        if (firstJoinSuccess) {
            vm.deal(player2, playerDeposit);
            vm.prank(player2);

            bool secondJoinReverted = false;
            
            try priceBet.join{value: playerDeposit}() {
                secondJoinReverted = false;
            } catch {
                secondJoinReverted = true;
            }

            assert(secondJoinReverted);
        }
    }
}