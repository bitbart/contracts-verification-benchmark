//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version missing `require(success)` after low-level call in `withdraw`

contract Bank {
    mapping (address user => uint credit) credits;

    function deposit() public payable {
        credits[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public returns (bool) {
        require(amount > 0);
        require(amount <= credits[msg.sender]);

        credits[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        return success;
    }
}

