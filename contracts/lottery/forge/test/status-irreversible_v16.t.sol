// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v16.sol";

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
    vm.deal(p0, bet);
    vm.deal(p1, bet);
    h0 = lottery.hashing(s0);
    h1 = lottery.hashing(s1);
  }
  function test_status_irreversible() public {
    vm.prank(p0);
    lottery.join0{value: bet}(h0);

    vm.prank(p1);
    lottery.join1{value: bet}(h1);

    assertTrue(lottery.status() == Lottery.Status.Reveal0);
    vm.prank(p0);
    lottery.reveal0(s0);

    assertTrue(lottery.status() == Lottery.Status.Reveal0);
  }
}
