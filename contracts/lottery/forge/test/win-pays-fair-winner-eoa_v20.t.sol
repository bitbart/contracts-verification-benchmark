// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v20.sol";

contract LotteryTest is Test {
  Lottery lottery;
  address p0 = makeAddr("p0");
  address p1 = makeAddr("p1");
  address attacker = makeAddr("attacker");
  uint bet = 1 ether;

  string s0 = "aa";
  string s1 = "bb";

  bytes32 h0;
  bytes32 h1;

  function setUp() public {
    lottery = new Lottery();
    vm.deal(p0, 2 ether);
    vm.deal(p1, 2 ether);

    h0 = lottery.hashing(s0);
    h1 = lottery.hashing(s1);
  }

  function test_win_pays_fair_winner_eoa() public {
    vm.prank(p0);
    lottery.join0{value: bet}(h0);

    vm.prank(p1);
    lottery.join1{value: bet}(h1);

    vm.prank(p0);
    lottery.reveal0(s0);

    vm.prank(p1);
    lottery.reveal1(s1);

    assertTrue(lottery.status() == Lottery.Status.Win);
    assertEq(lottery.compute_winner(payable(p0), payable(p1), s0, s1), payable(p0));

    vm.prank(attacker);
    lottery.win();

    assertEq(lottery.winner(), p0);
    assertEq(address(lottery).balance, 0);
    assertEq(attacker.balance, 2 * bet);
    assertEq(p0.balance, 1 ether);
    assertEq(p1.balance, 1 ether);
    assertTrue(lottery.status() == Lottery.Status.End);
  }
}
