// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >= 0.8.2;

/// @custom:version v2 mutation with a fixed XR

import "./lib/IERC20.sol"; 

contract LendingProtocol {
    // workaround for bug in solc v0.8.30
    address constant ZERO_ADDRESS = address(0x0000000000000000000000000000000000000000);

    uint256 public immutable tLiq = 666_666; // Collateralization threshold (multiplied by 1000000)

    // token reserves in the LendingProtocol
    mapping(address => uint256) public reserves; // token -> amount

    // amount of credit tokens held by each user
    mapping(address => mapping(address => uint256)) public credit; // token -> user -> amount 
    // amount of debit tokens held by each user
    mapping(address => mapping(address => uint256)) public debit; // token -> user -> amount

    // total amount of credit tokens (used to compute exchange rate)
    mapping(address => uint256) public sum_credits; // token -> amount

    // total amount of debit tokens (used to compute exchange rate)
    mapping(address token => uint debit) public sum_debits; // token -> amount
    // borrow index at last borrow/repay (starts at 1e6) 
    mapping (address token => uint index) public sum_debits_index;

    // global borrow index (starts at 1e6)
    uint public global_borrow_index = 1e6;
    // last time when global borrow index was updated 
    uint public last_global_update = 0;

    // users' borrow index
    mapping (address token => mapping (address borrower => uint index)) borrow_index;

    // token prices
    mapping (address token => uint256 price) prices;

    IERC20 public tok0;
    IERC20 public tok1;

    address[] public tokens;

    uint public immutable blockPeriod = 1_000_000;
    uint public immutable ratePerPeriod = 100_000; // interest rate per period * 1e6 (10%)

    // Constructor accepts arrays of borrow tokens and collateral tokens
    constructor(IERC20 _tok0, IERC20 _tok1) {
        tok0 = _tok0;
        tok1 = _tok1;
        require(tok0 != tok1);
        tokens.push(address(tok0));
        tokens.push(address(tok1));

        sum_debits_index[address(tok0)] = 1e6;
        sum_debits_index[address(tok1)] = 1e6;

        prices[address(tok0)] = 1;
        prices[address(tok1)] = 2;
    }

    // XR(t) returns the exchange rate for token t (multiplied by 1e6)
    function XR(address token) public view returns (uint) {
        require (_isValidToken(token), "Invalid token");
        return 1e6;
    }

    function _valCredit(address a) internal view returns (uint256) {
        uint256 val = 0;
        for (uint i = 0; i < tokens.length; i++) {
            val += credit[tokens[i]][a] * XR(tokens[i]) * getPrice(tokens[i]);
        }
        return val;
    }

    function _valDebit(address a) internal view returns (uint256) {
        uint256 val = 0;
        for (uint i = 0; i < tokens.length; i++) {
            val += debit[tokens[i]][a] * getPrice(tokens[i]);
        }
        return val;
    }

    // Assumes that interests on sum_debits and on all debits of borrower a have been accrued
    function _isCollateralized(address a) internal view returns (bool) {
        uint vdA = _valDebit(a); 
        if (vdA == 0) {
            return true; // No debt, so always collateralized
        }
        // health factor (multiplied by 10e6)
        uint256 hf = (_valCredit(a) * tLiq) / vdA;
        return (hf >= 1e6);
    }

    function _isValidToken(address token) internal view returns (bool) {
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                return true;
            }
        }
        return false;
        // in this version, this is equivalent to:
        // return (token == address(tok0) || token == address(tok1));
    }

    function isValidToken(address token) public view returns (bool) {
        return _isValidToken(token);
    }

    function isInterestAccrued(address token) public view returns (bool) {
        // should use last_global_update instead?
        return (sum_debits_index[token] == global_borrow_index);
    }

    // lazy interest accrual
    // (disclaimer: this implementation is only for compatibility with v1: here, interests accrue over time)
    function accrueInt() public view {
        require(block.number == last_global_update + blockPeriod);
    }

    function _calculate_linear_interest() internal view returns (uint) {
        uint elapsed = block.number - last_global_update;
        uint multiplier = 1e6 + (ratePerPeriod * elapsed) / blockPeriod;
        return multiplier;
    }

    function _update_global_borrow_index() internal {
        if (last_global_update == 0) {
            global_borrow_index = 1e6;
            last_global_update = block.number;    
        }
        else if (block.number > last_global_update) {
            uint multiplier = _calculate_linear_interest();
            global_borrow_index = (global_borrow_index * multiplier) / 1e6;
            last_global_update = block.number;
        }
    }
    
    modifier updateBorrowIndex() {
        _update_global_borrow_index();
        _;
    }

    function _get_accrued_debt(address token, address borrower) internal view returns (uint) {
        uint current_debt = debit[token][borrower];
        if (current_debt == 0) {
            return 0; // No debt, so no accrued debt
        }
        uint accrued_debt = (current_debt * global_borrow_index) / borrow_index[token][borrower];
        return accrued_debt;
    }

    function deposit(uint amount, address token_addr) public {
        require(amount > 0, "Deposit: amount must be greater than zero");
        require(
            _isValidToken(token_addr),
            "Deposit: invalid token"
        );
        IERC20 token = IERC20(token_addr);

        // computes XR in the pre-state
        uint xr = XR(token_addr);

        token.transferFrom(msg.sender, address(this), amount);
        reserves[token_addr] += amount;

        // credit tokens for liquidity provider
        uint amount_credit = (amount * 1e6) / xr;
        credit[token_addr][msg.sender] += amount_credit;
        sum_credits[token_addr] += amount_credit;
    }

    function borrow(uint amount, address token_addr) public updateBorrowIndex {
        require(amount > 0, "Borrow: amount must be greater than zero");
        require(
            _isValidToken(token_addr),
            "Borrow: invalid token"
        );

        // Check if the reserves are sufficient
        require(reserves[token_addr] >= amount, "Borrow: insufficient reserves");

        // Transfer tokens to the borrower
        IERC20 token = IERC20(token_addr);
        token.transfer(msg.sender, amount);

        reserves[token_addr] -= amount;
    
        // Update user's debt and index
        uint debt = _get_accrued_debt(token_addr, msg.sender);
        debit[token_addr][msg.sender] = debt + amount;
        borrow_index[token_addr][msg.sender] = global_borrow_index;    

        // Update total debt
        uint tot_debt = (sum_debits[token_addr] * global_borrow_index) / sum_debits_index[token_addr];
        sum_debits[token_addr] = tot_debt + amount;
        sum_debits_index[token_addr] = global_borrow_index;

        // Check if the borrower is collateralized in the post-state
        require(_isCollateralized(msg.sender), "Borrow: user is not collateralized");
    }

    function repay(uint amount, address token_addr) public updateBorrowIndex {
        require(amount > 0, "Repay: amount must be greater than zero");
        require(
            _isValidToken(token_addr),
            "Repay: invalid token"
        );

        uint debt = _get_accrued_debt(token_addr, msg.sender);

        require(
            debt >= amount,
            "Repay: insufficient debts"
        );

        IERC20 token = IERC20(token_addr);
        token.transferFrom(msg.sender, address(this), amount);

        reserves[token_addr] += amount;

        // Update user's debt and index
        debit[token_addr][msg.sender] = debt - amount;
        borrow_index[token_addr][msg.sender] = global_borrow_index;    

        // Update total debt
        uint tot_debt = (sum_debits[token_addr] * global_borrow_index) / sum_debits_index[token_addr];
        sum_debits[token_addr] = tot_debt - amount;
        sum_debits_index[token_addr] = global_borrow_index;
    }

    function redeem(uint amount, address token_addr) public {
        require(amount > 0, "Redeem: amount must be greater than zero");
        require(
            _isValidToken(token_addr),
            "Redeem: invalid token"
        );

        require(
            credit[token_addr][msg.sender] >= amount,
            "Redeem: insufficient credits"
        );

        // computes XR in the pre-state
        uint xr = XR(token_addr);

        uint amount_rdm = (amount * xr) / 1e6;
        require(
            reserves[token_addr] >= amount_rdm,
            "Redeem: insufficient reserves"
        );

        IERC20 token = IERC20(token_addr);
        token.transfer(msg.sender, amount_rdm);

        reserves[token_addr] -= amount_rdm;
        credit[token_addr][msg.sender] -= amount;
        sum_credits[token_addr] -= amount;
    
        // Check if the user is collateralized in the post-state
        require(_isCollateralized(msg.sender), "Redeem: user is not collateralized");
    }

    function liquidate(uint amount, address token_debit, address debtor, address token_credit) public pure {
        // in this version, liquidate is disabled
    }

    function getPrice(address token_addr) public view returns (uint256) {
        require(
            _isValidToken(token_addr),
            "Redeem: invalid token"
        );
        return prices[token_addr];
    }

    function getAccruedDebt(address token_addr, address borrower) public view returns (uint){
        require(
            _isValidToken(token_addr),
            "GetAccruedDebt: invalid token"
        );

        if (borrow_index[token_addr][borrower] == 0) return 0;

        // Update globalBorrowIndex
        uint _global_borrow_index = 0;
        if (last_global_update == 0) {
           _global_borrow_index = 1e6; 
        }
        else if (block.number > last_global_update) {
            uint multiplier = _calculate_linear_interest();
            _global_borrow_index = (global_borrow_index * multiplier) / 1e6;
        }
        else {
            _global_borrow_index = global_borrow_index;
        }

        // _get_accrued_debt
        uint current_debt = debit[token_addr][borrower];
        if (current_debt == 0) {
            return 0; // No debt, so no accrued debt
        }
        uint accrued_debt = (current_debt * _global_borrow_index) / borrow_index[token_addr][borrower]; 
        return accrued_debt;
    }

    function getUpdatedSumDebits(address token_addr) public view returns (uint) {
        require(
            _isValidToken(token_addr),
            "getUpdatedSumDebits: invalid token"
        );
        // Update globalBorrowIndex
        uint _global_borrow_index = 0;
        if (last_global_update == 0) {
           _global_borrow_index = 1e6; 
        }
        else if (block.number > last_global_update) {
            uint multiplier = _calculate_linear_interest();
            _global_borrow_index = (global_borrow_index * multiplier) / 1e6;
        }
        else {
            _global_borrow_index = global_borrow_index;
        }

        uint tot_debt = (sum_debits[token_addr] * _global_borrow_index) / sum_debits_index[token_addr];

        return tot_debt;
    }

    function getBorrowersLength() public pure returns (uint) {
        return 0;
    }
}
