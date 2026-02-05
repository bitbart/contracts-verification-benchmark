//SPDX-License-Identifier: GPL-3.0-only
pragma solidity >= 0.8.2;

/// @custom:version `deposit` and `withdraw` limits for non-owner users, with owner exempt from limits; `withdraw` uses `transfer` instead of low-level call 

contract Bank {
    mapping (address user => uint credit) private credits;
    address public immutable owner; // owner of the contract, exempt from limits
    uint public immutable opLimit;  // deposit & withdrawal limit (does not apply to the owner)

    modifier validAmount(uint amount) {
        require(amount > 0, "Amount must be greater than zero");
        if (msg.sender != owner) {
            require(amount <= opLimit, "Amount exceeds operation limit");
        }
        _;
    }

    constructor(uint _opLimit) {
        require(_opLimit > 0);
        owner = msg.sender;
        opLimit = _opLimit;
    }

    function deposit() public payable validAmount(msg.value) {
        credits[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public validAmount(amount) {
        require(amount <= credits[msg.sender], "Insufficient credits");
        credits[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}