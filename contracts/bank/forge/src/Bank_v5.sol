//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version no `amount <= credits[msg.sender]` check and `credits[msg.sender]` is incremented by `amount + 1` in `deposit`

contract Bank {
    mapping (address user => uint credit) credits;

    function deposit() public payable {
        credits[msg.sender] += msg.value + 1;
    }

    function withdraw(uint amount) public {
        require(amount > 0);

        credits[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }
}
