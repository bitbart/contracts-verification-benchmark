//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version no `amount <= credits[msg.sender]` check and `amount + 1` is transferred to `msg.sender` in `withdraw`

contract Bank {
    mapping (address user => uint credit) credits;

    function deposit() public payable {
        credits[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        require(amount > 0);

        credits[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount + 1}("");
        require(success);
    }
}
