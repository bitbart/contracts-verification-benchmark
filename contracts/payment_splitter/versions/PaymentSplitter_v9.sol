// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

/// @custom:version owner can withdraw remaining balance & payees can have zero shares

contract PaymentSplitter {
    uint256 private totalShares;
    uint256 private totalReleased;

    mapping(address => uint256) private shares;
    mapping(address => uint256) private released;
    address[] private payees;
    address payable owner;

    // workaround for bug in solc v0.8.30
    address constant ZERO_ADDRESS = address(0x0000000000000000000000000000000000000000);

    constructor(address[] memory payees_, uint256[] memory shares_) payable {
        require(
            payees_.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees_.length > 0, "PaymentSplitter: no payees");

        require (payees_[0] == msg.sender, "PaymentSplitter: first payee must be the owner");
        owner = payable(msg.sender);

        for (uint256 i = 0; i < payees_.length; i++) {
            addPayee(payees_[i], shares_[i]);
        }
    }

    receive() external payable virtual {}

    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased;
        return pendingPayment(account, totalReceived, released[account]);
    }

    function release(address payable account) public virtual {
        // require(shares[account] > 0, "PaymentSplitter: account has no shares"); // should not be checked if  shares can be 0

        uint256 payment = releasable(account);

        if(payment != 0) {
            // totalReleased is the sum of all values in released.
            // If "totalReleased += payment" does not overflow, then "released[account] += payment" cannot overflow.
            totalReleased += payment;
            unchecked {
                released[account] += payment;
            }

            (bool success, ) = account.call{value: payment}("");
            require(success);
        }
        else {
            (bool success, ) = owner.call{value: 1}("");
            require(success);
        }
    }

    function pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * shares[account]) / totalShares - alreadyReleased;
    }

    function addPayee(address account, uint256 shares_) private {
        require(
            account != ZERO_ADDRESS,
            "PaymentSplitter: account is the zero address"
        );
        require(
            shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        payees.push(account);
        shares[account] = shares_;
        totalShares = totalShares + shares_;
    }

    // Getters

    function isPayee(address a) public view returns (bool) {
        for (uint i; i < payees.length; i++) if (payees[i] == a) return true;
        return false;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getTotalReleasable() public view returns (uint) {
        uint _total_releasable = 0;
        for (uint i = 0; i < payees.length; i++) {
            _total_releasable += releasable(payees[i]);
        }
        return _total_releasable;
    }

    function getPayee(uint index) public view returns (address) {
        require(index < payees.length);
        return payees[index];
    }

    function getShares(address addr) public view returns (uint) {
        return shares[addr];
    }

    function getReleased(address addr) public view returns (uint) {
        return released[addr];
    }

    function getSumOfShares() public view returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < payees.length; i++) {
            sum += shares[payees[i]];
        }
        return sum;
    }

    function getSumOfReleased() public view returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < payees.length; i++) {
            sum += released[payees[i]];
        }
        return sum;
    }

    function getPayeesLength() public view returns (uint) {
        return payees.length;
    }

    function getTotalShares() public view returns (uint) {
        return totalShares;
    }

    function getTotalReleased() public view returns (uint) {
        return totalReleased;
    }
}
