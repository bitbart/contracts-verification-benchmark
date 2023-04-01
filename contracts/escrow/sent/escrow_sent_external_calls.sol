// SPDX-License-Identifier: GPLv3
pragma solidity >= 0.8.2;

contract Escrow {
    uint end_join;      // last block of the join phase
    uint end_choice;    // last block of the choice phase
    uint end_redeem;    // last block of the redeem phase

    uint fee_rate;      // fee_rate == 20 -> 0.20%

    address buyer;
    address seller;
    address escrow;
    uint deposit;       // buyer's deposit

    uint init_deposit;  // aux
    uint sent;          // aux: amount sent from this contract

    // changing the order of the following 2 lines impacts a lot on the speed
    uint prev_t_id;
    uint t_id;          
    mapping(uint => uint) blockn;   // maps the id of a transaction 
                                    // to the number of the corresponding block

    address buyer_choice;   // recipient of the deposit
    address seller_choice;  // recipient of the deposit
    address eChoice;        // choice of the escrow

    constructor (
        address _escrow, 
        uint _end_join, 
        uint _end_choice, 
        uint _end_redeem, 
        uint _fee_rate) {
        
        blockn[t_id] = block.number;
        require(blockn[t_id] < _end_join);
        require(_end_join < _end_choice);
        require(_end_choice < _end_redeem);

        require(_fee_rate <= 10000);    // The fee cannot be more then the deposit

        escrow = _escrow;
        end_join = _end_join;
        end_choice = _end_choice;
        end_redeem = _end_redeem;
        fee_rate = _fee_rate;
    }

    modifier beforeEndJoin() {
        require(blockn[t_id] < end_join);
        _;
    }
    
    modifier beforeEndChoice() {
        require(blockn[t_id] < end_choice);
        _;
    }

    modifier beforeEndReedem() {
        require(blockn[t_id] < end_redeem);
        _;
    }

    modifier afterEndReedem() {
        require(blockn[t_id] >= end_redeem);
        _;
    }
     
    modifier nonZeroSender() {
        require(msg.sender != address(0));  // this should probably be a default assumption
        _;
    }

    modifier new_t() {
        prev_t_id = t_id;
        t_id += 1;
        blockn[t_id] = blockn[prev_t_id] + 1;
        require(blockn[t_id] >= blockn[prev_t_id]);
        _;
    }
    
    /*****************
          Join Phase
        *****************/
    function join(address _seller) public payable new_t beforeEndJoin nonZeroSender {

        require(msg.sender != _seller);
        buyer = msg.sender;
        seller = _seller;
        deposit = msg.value;
        init_deposit = msg.value;

        require(deposit == init_deposit);
    }

    /*****************
         Choice Phase
        *****************/
    function choose(address _choice) public new_t beforeEndChoice {
        
        require(msg.sender == buyer || msg.sender == seller);    // may be redundant

        if (msg.sender == seller) {
            seller_choice = _choice;
        } else if (msg.sender == buyer) {
            buyer_choice = _choice;
        }
    }
 
    /*****************
         Redeem Phase 
        *****************/
    // The seller has not made a choice
    function redeem_without_seller() public new_t beforeEndReedem nonZeroSender {

        require(msg.sender == buyer);
        require(seller_choice == address(0));
        require(blockn[t_id] >= end_choice);

        uint amount = deposit;
        deposit -= amount;
        sent += amount; 

        (bool success,) = buyer.call{value: amount}("");      
        require(success);
    }

    function redeem() public new_t beforeEndReedem nonZeroSender {

        require(msg.sender == seller);
        require(buyer_choice == seller_choice);
        require(seller_choice != address(0));
        require(blockn[t_id] >= end_choice);

        uint amount = deposit;
        deposit -= amount;
        sent += amount;

        (bool success,) = seller_choice.call{value: amount}("");
        require(success);
    }

    /*****************
          Arbitrate
        *****************/
    function arbitrate(address _eChoice) public new_t afterEndReedem {

        require(msg.sender == escrow);
        require(_eChoice == buyer_choice || _eChoice == seller_choice);
        require(eChoice != address(0));         // can choose only once
        
        eChoice = _eChoice;

        uint fee = deposit * fee_rate / 10000;
        deposit -= fee;
        sent += fee;

        (bool success,) = escrow.call{value: fee}("");
        require(success);
    }

    function redeem_arbitrated() public new_t {

        require(eChoice != address(0));

        uint amount = deposit;
        deposit -= amount;
        sent += amount;

        (bool success,) = eChoice.call{value: amount}("");
        require(success);
    }

    function invariant() public view {
        assert(sent <= init_deposit);
    }
}