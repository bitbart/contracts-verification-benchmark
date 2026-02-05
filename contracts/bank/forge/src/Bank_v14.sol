//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version owner can blacklist addresses from `deposit` and `withdraw`

contract Bank {
    mapping (address user => uint credit) credits;
    mapping (address user => bool) l;
    address public immutable owner; // owner of the contract

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        if (l[msg.sender]) {
            require(msg.value == 0);
        } else {
            credits[msg.sender] += msg.value;
        }
    }

    function withdraw(uint amount) public {
        require(amount > 0);
        require(amount <= credits[msg.sender]);

        if (l[msg.sender]) {
            require(amount == 0);
        } else {
            credits[msg.sender] -= amount;
            (bool success,) = msg.sender.call{value: amount}("");
            require(success);
        }
    }

    function setl(address a, bool b) public {
        require(msg.sender == owner);
        l[a] = b;
    }
}

