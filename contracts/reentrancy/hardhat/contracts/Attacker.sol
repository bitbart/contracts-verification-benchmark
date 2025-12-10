
    // SPDX-License-Identifier: UNLICENSED
    pragma solidity ^0.8.25;

    interface IReentrancy {
        function s(uint256 _x) external;
    }

    contract Attacker {
        address public target;
        constructor(address _target) {
            target = _target;
        }
        // Triggered by Reentrancy.f via a.call("")
        fallback() external {
            // Reenter and set x to 1
            IReentrancy(target).s(1);
        }
    }