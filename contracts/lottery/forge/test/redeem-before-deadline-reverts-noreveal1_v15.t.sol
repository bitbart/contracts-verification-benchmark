// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v15.sol";

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
  function test_redeem_before_deadline_reverts_noreveal1() public {
    vm.prank(p0);
    lottery.join0{value: bet}(h0);

    vm.prank(p1);
    lottery.join1{value: bet}(h1);

    vm.prank(p0);
    lottery.reveal0(s0);

    assertTrue(lottery.status() == Lottery.Status.Reveal1);

    vm.roll(lottery.end_join() + 1);
    assertTrue(block.number > lottery.end_join());
    assertTrue(block.number <= lottery.end_reveal1());

    vm.prank(p0);
    lottery.redeem0_noreveal1();

    assertEq(address(lottery).balance, 0);
    assertEq(p0.balance, 3 ether);
    assertEq(p1.balance, 1 ether);
    assertTrue(lottery.status() == Lottery.Status.End);
  }
}
