// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/// @custom:version `reveal` function may be bribed to change committed `hash`
contract Htlc {
    address payable public owner;  
    address payable public verifier;
    bytes32 public hash;
    bool public isCommitted;
    uint public start;
    uint public fee;
    uint public waitTime;
    
    constructor(address payable v) {
        owner = payable(msg.sender);
        verifier = v;
        start = block.number;
        isCommitted = false;
        fee = 1 ether;
        waitTime = 1000;
    }

    function commit(bytes32 h) public payable {
        require(msg.sender == owner);
        require(msg.value >= fee);
        require(!isCommitted);

        hash = h;
        isCommitted = true;
    }

    function reveal(string memory s) public payable {
        require(msg.sender == owner);
        require(isCommitted);       
        if (msg.value >= fee) {
            hash = hashing(s);
        }
        require(hashing(s) == hash);

        uint _to_send = address(this).balance;
        (bool success,) = owner.call{value: _to_send}("");
        require(success, "Transfer failed.");    
    }

    function timeout() public {
        require(block.number > start + waitTime);
        require(isCommitted);       

        uint _to_send = address(this).balance;
        (bool success,) = verifier.call{value: _to_send}("");
        require(success, "Transfer failed.");     
    }

    function hashing(string memory s) public pure returns (bytes32){
        return keccak256(abi.encodePacked(s));
    }
}
