//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version in `withdraw`, no `amount <= credits[msg.sender]` check, unchecked decrement, and no `require(success)` check

contract Bank {
    mapping (address user => uint credit) credits;

    function deposit() public payable {
        credits[msg.sender] += msg.value - 1;
    }

    function withdraw(uint amount) public returns (bool) {
        require(amount > 0);

        unchecked {
            credits[msg.sender] -= amount;
        }

        (bool success,) = msg.sender.call{value: amount}("");
        return(success);
    }
}
