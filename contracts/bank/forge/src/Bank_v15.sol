//SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.2;

/// @custom:version maximum number of operations per block, and uses `transfer` instead of low-level call in `withdraw`.

contract Bank {
    mapping (address user => uint credit) credits;
    uint public immutable opb = 15;
    uint public opsInCurrentBlock;
    uint public currentBlockNo;

    constructor() {
        currentBlockNo = block.number;
        opsInCurrentBlock = 0;
    }

    function deposit() public payable {
        if (block.number != currentBlockNo) {
            currentBlockNo = block.number;
            opsInCurrentBlock = 0;
        }
        require(opsInCurrentBlock < opb, "Maximum operations per block exceeded");
        credits[msg.sender] += msg.value;
        opsInCurrentBlock++;
    }

    function withdraw(uint amount) public {
        if (block.number != currentBlockNo) {
            currentBlockNo = block.number;
            opsInCurrentBlock = 0;
        }
        require(opsInCurrentBlock < opb, "Maximum operations per block exceeded");
        require(amount > 0);
        require(amount <= credits[msg.sender]);

        credits[msg.sender] -= amount;

        payable(msg.sender).transfer(amount);

        opsInCurrentBlock++;
    }
}

