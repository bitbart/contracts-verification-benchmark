// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >= 0.8.2;

/// @custom:version v1 mutation with a fixed XR

import "./lib/IERC20.sol";

contract LendingProtocol {
    // workaround for bug in solc v0.8.30
    address constant ZERO_ADDRESS = address(0x0000000000000000000000000000000000000000);

    uint256 public immutable tLiq = 666_666; // Collateralization threshold (multiplied by 1000000)

    // token reserves in the LendingProtocol
    mapping(address => uint256) public reserves; // token -> amount

    // amount of credit tokens held by each user
    mapping(address => mapping(address => uint256)) public credit; // token -> user -> amount 
    // amount of debit tokens held by each user (without interests)
    mapping(address => mapping(address => uint256)) public debit; // token -> user -> amount

    // total amount of credit tokens (used to compute exchange rate)
    mapping(address => uint256) public sum_credits; // token -> amount
    // total amount of debit tokens (used to compute exchange rate)
    mapping(address => uint256) public sum_debits; // token -> amount

    // token prices
    mapping (address token => uint256 price) prices;

    IERC20 public tok0;
    IERC20 public tok1;

    address[] public tokens;

    // in this (unrealistic) version, we record borrowers in an array
    address[] public borrowers;
    // and we delagate the owner to trigger interest accruals 
    address owner;

    uint public immutable ratePerPeriod = 100_000; // interest rate per tick * 1e6 (10%)

    // Constructor accepts arrays of borrow tokens and collateral tokens
    constructor(IERC20 _tok0, IERC20 _tok1) {
        tok0 = _tok0;
        tok1 = _tok1;
        require(tok0 != tok1);
        tokens.push(address(tok0));
        tokens.push(address(tok1));

        // in this version of the contract, token prices are constant
        prices[address(tok0)] = 1;
        prices[address(tok1)] = 2;

        owner = msg.sender;
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
        // return (token == address(tok0) || token == address(tok1));
    }

    function isValidToken(address token) public view returns (bool) {
        return _isValidToken(token);
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

        uint amount_credit = (amount * 1e6) / xr;
 
        credit[token_addr][msg.sender] += amount_credit;
        sum_credits[token_addr] += amount_credit;
    }

    function borrow(uint amount, address token_addr) public {
        require(amount > 0, "Borrow: amount must be greater than zero");
        require(
            _isValidToken(token_addr),
            "Borrow: invalid token"
        );

        // Check if the reserves are sufficient
        require(reserves[token_addr] >= amount, "Borrow: insufficient reserves");

        // records the borrower, if not already present in the array
        if (!is_borrower(msg.sender)) {
            borrowers.push(msg.sender);
        }

        // Transfer tokens to the borrower
        IERC20 token = IERC20(token_addr);
        token.transfer(msg.sender, amount);

        reserves[token_addr] -= amount;
        debit[token_addr][msg.sender] += amount;
        sum_debits[token_addr] += amount;

        // Check if the borrower is collateralized in the post-state
        require(_isCollateralized(msg.sender), "Borrow: user is not collateralized");
    }


    function is_borrower(address a) public view returns (bool) {
        for(uint i = 0; i < borrowers.length; i++) {
            if (borrowers[i] == a) {
                return true;
            }
        }
        return false;
    }

    function repay(uint amount, address token_addr) public {
        require(amount > 0, "Repay: amount must be greater than zero");
        require(
            _isValidToken(token_addr),
            "Repay: invalid token"
        ); 

        require(
            debit[token_addr][msg.sender] >= amount,
            "Repay: insufficient debts"
        );

        IERC20 token = IERC20(token_addr);
        token.transferFrom(msg.sender, address(this), amount);

        reserves[token_addr] += amount;
        debit[token_addr][msg.sender] -= amount;
        sum_debits[token_addr] -= amount;
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

    function isInterestAccrued(address token) public pure returns (bool) {
        // in this version, interests are accrued eagerly
        return true;
    }

    // eager interest accrual, triggered by the owner
    // (disclaimer: this implementation is unrealistic, since it iterates over all tokens/borrowers)
    function accrueInt() public {
        require (msg.sender == owner);
        for (uint i = 0; i < tokens.length; i++) {
            for (uint j=0; j<borrowers.length; j++) {
                uint accrued = (debit[tokens[i]][borrowers[j]] * ratePerPeriod) / 1e6;
                debit[tokens[i]][borrowers[j]] += accrued;
                sum_debits[tokens[i]] += accrued;
            }
        }
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

    /** Functions for compatibility with LendingProtocol_v2 */

    function getAccruedDebt(address token, address user) public view returns (uint256) {
        // in this version, we do not have accrued debt
        return debit[token][user];
    }

    function getUpdatedSumDebits(address token) public view returns (uint256) {
        return sum_debits[token];
    }

    function getBorrowersLength() public view returns (uint) {
        return borrowers.length;
    }
}
