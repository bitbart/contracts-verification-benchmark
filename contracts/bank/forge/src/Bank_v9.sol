//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version `deposit` and `withdraw` are non-reentrant

import "./lib/ReentrancyGuard.sol";

contract Bank is ReentrancyGuard {
    mapping (address user => uint credit) credits;

    function deposit() public payable nonReentrant {
        credits[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public nonReentrant {
        require(amount > 0);
        require(amount <= credits[msg.sender]);

        credits[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }
}

