// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >= 0.8.2;

/// @custom:version redeem0_noreveal1 transfers only half the balance
contract Lottery {
    address public owner;

    address payable public player0;
    address payable public player1; 
    address payable public winner;

    bytes32 public hash0;
    bytes32 public hash1;

    string public secret0;
    string public secret1;

    uint256 public bet_amount;

    enum Status {
        Join0,
        Join1,
	    Reveal0,
	    Reveal1,
	    Win,
        End
    }

    uint public end_join;
    uint public end_reveal0;
    uint public end_reveal1;
    
    Status public status;
    
    uint constant DELTA_TIME = 1000;
    uint constant public MINIMUM_BET = 0.01 ether;

    constructor() {
        owner = msg.sender;
	    status = Status.Join0;
	    end_join = block.number + DELTA_TIME;
	    end_reveal0 = end_join + DELTA_TIME;
        end_reveal1 = end_reveal0 + DELTA_TIME;
    }

    /// `player0` joins the lottery by paying the bet and committing to a secret
    function join0(bytes32 h) payable public {
        require(status == Status.Join0);
        require(msg.value >= MINIMUM_BET);
        require(block.number <= end_join);

        player0 = payable(msg.sender);
        hash0 = h;
	    status = Status.Join1;
        bet_amount = msg.value;
    }

    /// `player1` joins the lottery by paying the bet and committing to another secret (the bet is the same for each player)
    function join1(bytes32 h) payable public {
        require(status == Status.Join1);
        require(h!=hash0);
        require(msg.value == bet_amount);
        require(msg.sender != player0);
        require(block.number <= end_join);

        player1 = payable(msg.sender);
        hash1 = h;	
    	status = Status.Reveal0;
    }

    /// if `player1` has not joined, `player0` can redeem their bet after a given deadline (`end_commit`).
    function redeem0_nojoin1() public {
	    require(status == Status.Join1);
        require(block.number > end_join);

        (bool success,) = player0.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
	    status = Status.End;
    } 
    
    /// `player0` reveals the first secret
    function reveal0(string memory s) public {
        require(status == Status.Reveal0);
        require(block.number <= end_reveal0);
        require(msg.sender == player0);
        require(hashing(s) == hash0);

        secret0 = s;
	    status = Status.Reveal1;
    }

    /// if `player0` has not revealed, `player1` can redeem both players' bets after a given deadline (`end_reveal0`); 
    function redeem1_noreveal0() public {
	    require(status == Status.Reveal0);
        require(block.number > end_reveal0);

        (bool success,) = player1.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
	    status = Status.End;
    } 
    
    /// once `player0` has revealed, `player1` reveals the secret
    function reveal1(string memory s) public {
        require(status == Status.Reveal1);
        require(block.number <= end_reveal1);
        require(msg.sender == player1);
        require(hashing(s)==hash1);

        secret1 = s;
	    status = Status.Win;
    }

    /// if `player1` has not revealed, `player0` can redeem both players' bets after a given deadline (`end_reveal0` plus a fixed constant)
    function redeem0_noreveal1() public {
	    require(status==Status.Reveal1);
        require(block.number > end_reveal1);

        (bool success,) = player0.call{value: address(this).balance / 2}("");
        require(success, "Transfer failed.");
	    status = Status.End;
    } 
    
    function compute_winner(address payable p0, address payable p1, string memory s0, string memory s1) public pure returns (address payable) {
        uint256 l0 = bytes(s0).length;
        uint256 l1 = bytes(s1).length;
        
        address payable w;
        
        if ((l0+l1) % 2 == 0)  w = p0;
        else w = p1;

        return w;
    }

    /// once both secrets have been revealed, the winner, who is fairly determined as a function of the two revealed secrets, can redeem the whole pot
    function win() public {
        require(status==Status.Win);
	
        winner = compute_winner(player0, player1, secret0, secret1);

        (bool success,) = winner.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
	    status = Status.End;
    }

    function hashing(string memory s) public pure returns (bytes32){
        return keccak256(abi.encodePacked(s));
    }

    function _status() public view returns (uint8) {
        return uint8(status);
    }
}
