// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2;

import {CommonBase} from "forge-std/Base.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

/// @notice Getter injected into every Bank version (see ../getters.sol)
interface IBankGetters {
    function getCredits(address user) external view returns (uint256);
}

/// @notice Contract user: a Bank user that is a smart contract.
///
/// When it receives ETH (e.g. from the low-level call in `withdraw`), its `receive`
/// SYMBOLICALLY chooses one of these behaviours:
///   0. accepts and does nothing (like an EOA)
///   1. reverts
///   2. makes an arbitrary symbolic call to Bank (svm.createCalldata),
///      executed by itself or by the other contract user (reentrancy)
///   3. forwards ETH to an arbitrary symbolic address
///
/// Bound: each contract user reacts at most once per transaction,
/// otherwise the exploration of reentrant calls would not terminate.
contract BankUser is CommonBase, SymTest {
    address public immutable bank;
    address public immutable handler;
    BankUser public peer;
    bool public reacted;

    constructor(address _bank) {
        bank = _bank;
        handler = msg.sender;
    }

    function setPeer(BankUser _peer) external {
        require(msg.sender == handler);
        peer = _peer;
    }

    /// @notice called by the Handler at the beginning of every transaction
    function newTransaction() external {
        require(msg.sender == handler);
        reacted = false;
    }

    receive() external payable {
        if (reacted) return;
        reacted = true;

        uint256 choice = svm.createUint(2, "receive_choice");
        if (choice == 0) return;
        if (choice == 1) revert();
        if (choice == 2) {
            BankUser actor = svm.createBool("receive_peer_acts") ? peer : this;
            actor.act(svm.createCalldata(bank), svm.createUint256("receive_call_value"));
            return;
        }
        address to = svm.createAddress("receive_to");
        uint256 value = svm.createUint256("receive_transfer_value");
        vm.assume(value <= address(this).balance);
        (bool ok,) = payable(to).call{value: value}("");
        ok; // the outcome is irrelevant: the user may ignore it
    }

    /// @notice call to Bank performed by this contract user (msg.sender = this)
    function act(bytes memory data, uint256 value) external {
        require(msg.sender == address(this) || msg.sender == address(peer));
        vm.assume(value <= address(this).balance);
        (bool ok,) = bank.call{value: value}(data);
        ok; // the outcome is irrelevant: the user may ignore it
    }
}

/// @notice Generic Handler for the Bank invariant tests.
///
/// Halmos calls `call(value)` with symbolic msg.sender, tx.origin and arguments.
/// The Handler forwards to Bank a symbolic call to ANY non-view function
/// of the version under test (svm.createCalldata), preserving
/// sender and tx.origin with vm.prank. Before and after the call it records the
/// ghost variables that the invariants use to reason about the transition.
///
/// The transaction sender is chosen symbolically among:
///   - an arbitrary EOA (Halmos' symbolic msg.sender);
///   - one of the two contract users (BankUser), which can react when they
///     receive ETH. Two contract users are needed so that, during the transaction
///     of one, the other can act on Bank (e.g. A's credit decreases inside a
///     `withdraw` by B).
/// The ghosts wrap the whole transaction, so they include the effects of
/// any reentrant calls.
///
/// `call` is NOT payable: with vm.prank Halmos charges the ETH of the forwarded
/// call to the simulated sender. If the Handler also received msg.value,
/// the user would pay twice and only 0-wei deposits would succeed.
///
/// In Halmos every address starts with an ETH balance of 0 (except the test contract),
/// so before the call the sender is guaranteed at least `value` wei:
/// this amounts to assuming that the user has enough ETH for the transaction.
///
contract BankHandler is CommonBase, SymTest {
    
    address public immutable bank;
    address public immutable user;
    BankUser public immutable userContract0;
    BankUser public immutable userContract1;

    // --- ghost: last (non-reverted) transaction executed on Bank ---
    bytes4 public lastSelector;
    address public lastSender;
    address public lastOrigin;
    uint256 public lastValue;
    uint256 public lastAmount;
    // tracked for the fixed `user` (A) — use when the property is about a specific known address
    uint256 public userCreditBefore;
    uint256 public userCreditAfter;
    uint256 public userBalanceBefore;
    uint256 public userBalanceAfter;
    // tracked for the actual sender — use when the property must hold for any address
    uint256 public senderCreditBefore;
    uint256 public senderCreditAfter;
    uint256 public senderBalanceBefore;
    uint256 public senderBalanceAfter;
    uint256 public bankBalanceBefore;
    uint256 public bankBalanceAfter;

    constructor(address _bank, address _user) {
        bank = _bank;
        user = _user;
        userContract0 = new BankUser(_bank);
        userContract1 = new BankUser(_bank);
        userContract0.setPeer(userContract1);
        userContract1.setPeer(userContract0);
    }

    function call(uint256 value) external {
        bytes memory data = svm.createCalldata(bank);

        // tx.origin is always an EOA (in particular neither address(0) nor a contract)
        vm.assume(tx.origin != address(0));
        vm.assume(tx.origin.code.length == 0);

        // sender: an arbitrary EOA or one of the contract users
        address sender = msg.sender;
        if (svm.createBool("sender_is_contract")) {
            sender = svm.createBool("sender_is_contract0") ? address(userContract0) : address(userContract1);
        } else {
            vm.assume(msg.sender.code.length == 0);
        }

        userContract0.newTransaction();
        userContract1.newTransaction();

        if (sender.balance < value) vm.deal(sender, value);

        uint256 creditBefore = IBankGetters(bank).getCredits(user);
        uint256 balanceBefore = user.balance;
        uint256 senderCreditBefore_ = IBankGetters(bank).getCredits(sender);
        uint256 senderBalanceBefore_ = sender.balance;
        uint256 bankBefore = bank.balance;

        vm.prank(sender, tx.origin);
        (bool ok,) = bank.call{value: value}(data);
        // a reverted transaction does not change the state: discard it
        require(ok);

        lastSelector = bytes4(data);
        lastSender = sender;
        lastOrigin = tx.origin;
        lastValue = value;
        uint256 amount;
        if (data.length >= 36) {
            // skip the length word (32 bytes) and the selector (4 bytes)
            assembly { amount := mload(add(data, 36)) }
        }
        lastAmount = amount;
        userCreditBefore = creditBefore;
        userCreditAfter = IBankGetters(bank).getCredits(user);
        userBalanceBefore = balanceBefore;
        userBalanceAfter = user.balance;
        senderCreditBefore = senderCreditBefore_;
        senderCreditAfter = IBankGetters(bank).getCredits(sender);
        senderBalanceBefore = senderBalanceBefore_;
        senderBalanceAfter = sender.balance;
        bankBalanceBefore = bankBefore;
        bankBalanceAfter = bank.balance;
    }
}
