// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v6.sol";

contract LotteryTest is Test {
  Lottery lottery;
  address p0 = makeAddr("p0");
  address p1 = makeAddr("p1");
  uint bet = 0.01 ether;

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
  function test_no_incentives_to_abort_eoa() public {
    vm.prank(p0);
    lottery.join0{value: bet}(h0);

    vm.prank(p1);
    lottery.join1{value: bet}(h1);

    vm.prank(p0);
    lottery.reveal0(s0);

    assertTrue(lottery.status() == Lottery.Status.Reveal1);

    uint256 p0BalanceBefore = p0.balance;
    uint256 p1BalanceBefore = p1.balance;

    vm.roll(lottery.end_reveal1() + 1);
    vm.prank(p0);
    lottery.redeem0_noreveal1();

    assertEq(address(lottery).balance, 0);
    assertEq(p0.balance, p0BalanceBefore);
    assertEq(p1.balance, p1BalanceBefore + 2*bet);
    assertTrue(lottery.status() == Lottery.Status.End);
  }
}
