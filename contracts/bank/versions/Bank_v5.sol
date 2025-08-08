//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version no `amount <= balances[msg.sender]` check and `balances[msg.sender]` is incremented by `amount + 1` in `deposit()`
contract Bank {
    mapping (address => uint) balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value + 1;
    }

    function withdraw(uint amount) public {
        require(amount > 0);
        //require(amount <= balances[msg.sender]);

        balances[msg.sender] -= amount;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success);
    }

}
