// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v4.sol";

contract LotteryTest is Test {
  Lottery lottery1;
  Lottery lottery2;

  address p0 = makeAddr("p0");
  address p1 = makeAddr("p1");
  uint bet = 1 ether;

  string s0 = "a";
  string s1 = "";

  bytes32 h0Even;
  bytes32 h1Even;
  bytes32 h0Odd;
  bytes32 h1Odd;

  function setUp() public {
    vm.deal(p0, 2 ether);
    vm.deal(p1, 2 ether);
    lottery1 = new Lottery();
    lottery2 = new Lottery(); 
  }

  function test_honest_player_profitability_eoa_redeem0_noreveal1() public {
    h0Even = lottery1.hashing(s0);
    h1Even = lottery1.hashing(s1);
    h0Odd = lottery2.hashing(s0);
    h1Odd = lottery2.hashing(s1);

    vm.startPrank(p0);
    lottery1.join0{value: bet}(h0Even);
    lottery2.join0{value: bet}(h0Odd);

    vm.startPrank(p1);
    lottery1.join1{value: bet}(h1Even);
    lottery2.join1{value: bet}(h1Odd);

    vm.stopPrank();

    uint snapshotId = vm.snapshotState();

    vm.prank(p0);
    lottery1.reveal0(s0);

    assertTrue(lottery1.status() == Lottery.Status.Reveal1);
    assertEq(address(lottery1).balance, 2*bet);

    uint256 p0BalanceBefore = p0.balance;
    vm.roll(lottery1.end_reveal1() + 1);

    vm.prank(p0);
    lottery1.redeem0_noreveal1();

    // Lottery 1 transfers half the balance
    assertEq(p0.balance, p0BalanceBefore + 1 ether);
    assertEq(address(lottery1).balance, 1 ether);
    assertTrue(lottery1.status() == Lottery.Status.End);
    
    vm.revertToState(snapshotId);

    vm.prank(p0);
    lottery2.reveal0(s0);

    vm.prank(p1);
    lottery2.reveal1(s1);

    assertTrue(lottery2.status() == Lottery.Status.Win);
    assertEq(lottery2.compute_winner(payable(p0), payable(p1), s0, s1), p1);

    uint256 p1BalanceBefore = p1.balance;
    vm.prank(p0);
    lottery2.win();

    // Lottery 2 transfers full balance
    assertEq(p1.balance, p1BalanceBefore + 2*bet);
    assertEq(address(lottery2).balance, 0);
    assertTrue(lottery2.status() == Lottery.Status.End);
  }
}
