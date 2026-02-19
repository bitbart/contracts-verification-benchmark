// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >= 0.8.2;


/// @custom:version `donate` and `withdraw` are non-reentrant.

import "../../../lib/ReentrancyGuard.sol";

contract Crowdfund is ReentrancyGuard {
    uint immutable end_donate;    // last block in which users can donate
    uint immutable goal;          // amount of ETH that must be donated for the crowdfunding to be succesful
    address immutable owner;      // receiver of the donated funds
    mapping(address => uint) public donation;

    constructor (address payable owner_, uint end_donate_, uint256 goal_) {
        owner = owner_;
        end_donate = end_donate_;
	    goal = goal_;	
    }
    
    function donate() public payable nonReentrant() {
        require (block.number <= end_donate);
        donation[msg.sender] += msg.value;
    }

    function withdraw() public nonReentrant {
        require (block.number > end_donate);
        require (address(this).balance >= goal);

        (bool succ,) = owner.call{value: address(this).balance}("");
        require(succ);
    }
    
    function reclaim() public { 
        require (block.number > end_donate);
        require (address(this).balance < goal);
        require (donation[msg.sender] > 0);

        uint amount = donation[msg.sender];
        donation[msg.sender] = 0;

        (bool succ,) = msg.sender.call{value: amount}("");
        require(succ);
    }
}

