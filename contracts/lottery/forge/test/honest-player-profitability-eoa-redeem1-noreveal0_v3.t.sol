// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v3.sol";

contract LotteryTest is Test {
  Lottery lottery;
  address p0 = makeAddr("p0");
  address p1 = makeAddr("p1");
  uint bet = 1 ether;

  string s0 = "a";
  string s1 = "b";

  bytes32 h0;
  bytes32 h1;

  function setUp() public {
    lottery = new Lottery();
    vm.deal(p0, 2 ether);
    vm.deal(p1, 2 ether);

    h0 = lottery.hashing(s0);
    h1 = lottery.hashing(s1);
  }
  
  function test_honest_player_profitability_eoa_redeem1_noreveal0() public {
    vm.prank(p0);
    lottery.join0{value: bet}(h0);

    vm.prank(p1);
    lottery.join1{value: bet}(h1);

    assertTrue(lottery.status() == Lottery.Status.Reveal0);
    assertEq(address(lottery).balance, 2*bet);

    uint256 p1BalanceBefore = p1.balance;

    vm.roll(lottery.end_reveal0() + 1);
    vm.prank(p1);
    lottery.redeem1_noreveal0();

    assertEq(p1.balance, p1BalanceBefore + bet);
    assertEq(address(lottery).balance, 1 ether);
    assertTrue(lottery.status() == Lottery.Status.End);
  }
}
