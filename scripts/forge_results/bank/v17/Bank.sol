//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version `withdraw` subtracts credits from `tx.origin`, but sends ETH to `msg.sender`

contract Bank {
    mapping (address user => uint credit) credits;

    function deposit() public payable {
        credits[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        require(amount > 0);
        require(amount <= credits[tx.origin]);

        credits[tx.origin] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }
}