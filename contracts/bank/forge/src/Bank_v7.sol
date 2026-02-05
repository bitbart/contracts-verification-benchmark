//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version `deposit` pays a unit fee to the owner

contract Bank {
    mapping (address user => uint credit) credits;
    address public immutable owner; // owner of the contract

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        credits[msg.sender] += (msg.value - 1);
        credits[owner] += 1; // owner gets 1 token for each deposit
    }

    function withdraw(uint amount) public {
        require(amount > 0);
        require(amount <= credits[msg.sender]);

        credits[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }
}

