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

    /// @notice Property: join-revert
    function check_join_revert(
        uint256 initialPot,
        uint256 timeout,
        uint256 exchangeRate,
        address player1,
        address player2,
        uint256 deposit,
        uint256 blockJump
    ) public {
        vm.assume(initialPot > 0 );
        vm.assume(timeout > 0);
        vm.assume(player1 != address(0));
        vm.assume(player2 != address(0));
        vm.assume(player1 != player2);

        uint256 deploymentBlock = block.number;

        Oracle oracle = new Oracle(100);
        vm.deal(address(this), initialPot);
        PriceBet priceBet;
        try new PriceBet{value: initialPot}(address(oracle), timeout, exchangeRate) returns (PriceBet deployed) {
            priceBet = deployed;
        } catch {
            return;
        }

        if (blockJump > timeout) {
            vm.roll(deploymentBlock + blockJump);
        }

        // Track state before calling join
        bool isDeadlinePassed = (block.number >= deploymentBlock + timeout); 
        
        // First join attempt with `deposit` and `player1`
        vm.deal(player1, deposit);
        vm.prank(player1);
        bool joinReverted = false;
        try priceBet.join{value: deposit}() {
            joinReverted = false;
        } catch {
            joinReverted = true;
        }

        // If any of the negative conditions hold, it MUST have reverted
        bool shouldRevert = (deposit != initialPot) || (blockJump > timeout);

        if (shouldRevert) {
            assert(joinReverted);
        }

        // If the first join actually succeeded, then a SECOND join by player2 must revert 
        if (!joinReverted) {
            vm.deal(player2, initialPot);
            vm.prank(player2);
            bool secondJoinReverted = false;
            try priceBet.join{value: initialPot}() {
                secondJoinReverted = false;
            } catch {
                secondJoinReverted = true;
            }

            assert(secondJoinReverted);
        }
    }
}