//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version `deposit` transfers part of `msg.value` to the owner

contract Bank {
    mapping (address user => uint credit) credits;
    address public immutable owner; // owner of the contract

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        if (msg.value > 1) {
            payable(owner).transfer(1);
            credits[msg.sender] += (msg.value - 1);
        }
        else {
            credits[msg.sender] += msg.value;
        }
    }

    function withdraw(uint amount) public {
        require(amount > 0);
        require(amount <= credits[msg.sender]);

        credits[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }
}

