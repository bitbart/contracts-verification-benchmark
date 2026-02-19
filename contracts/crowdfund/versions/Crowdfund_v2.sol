// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >= 0.8.2;


/// @custom:version end_donate = type(uint256).max i.e donation period never ends.
contract Crowdfund {
    uint immutable end_donate = type(uint).max;    // last block in which users can donate
    uint immutable goal;          // amount of ETH that must be donated for the crowdfunding to be succesful
    address immutable owner;      // receiver of the donated funds
    mapping(address => uint) public donation;

    constructor (address payable owner_, uint256 goal_) {
        owner = owner_;
	    goal = goal_;	
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