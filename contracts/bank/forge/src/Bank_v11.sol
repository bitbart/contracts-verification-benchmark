//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version owner can pause `deposit`

contract Bank {
    mapping (address user => uint credit) credits;
    address public immutable owner; // owner of the contract
    bool p;

    constructor() {
        owner = msg.sender;
        p = false;
    }

    function deposit() public payable {
        require(!p);
        credits[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        require(amount > 0);
        require(amount <= credits[msg.sender]);

        credits[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }

    function setP(bool _p) public {
        require(msg.sender == owner);
        p = _p;
    }
}

