// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >= 0.8.2;


/// @custom:version `owner` not immutable & `setOwner` allows any user to set itself as owner.
contract Crowdfund {
    uint immutable end_donate;    // last block in which users can donate
    uint immutable goal;          // amount of ETH that must be donated for the crowdfunding to be succesful
    address private owner;      // receiver of the donated funds
    mapping(address => uint) public donation;

    constructor (uint end_donate_, uint256 goal_) {
        end_donate = end_donate_;
	    goal = goal_;	
    }
    
    function setOwner(address payable user) public {
        owner = user;
    }

    function donate() public payable {
        require (block.number <= end_donate);
        donation[msg.sender] += msg.value;
    }

    function withdraw() public {
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
