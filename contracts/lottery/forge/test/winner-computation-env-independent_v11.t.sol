// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v11.sol";

contract LotteryTest is Test {
  Lottery lottery;
  address p0 = makeAddr("p0");
  address p1 = makeAddr("p1");

  string s0 = "a";
  string s1 = "b";

  function setUp() public {
    lottery = new Lottery();
  }
  function test_winner_computation_env_independent() public {
    vm.warp(100);
    address payable winnerAtEvenTimestamp = lottery.compute_winner(payable(p0), payable(p1), s0, s1);

    vm.warp(101);
    address payable winnerAtOddTimestamp = lottery.compute_winner(payable(p0), payable(p1), s0, s1);

    assertEq(winnerAtEvenTimestamp, p0);
    assertEq(winnerAtOddTimestamp, p1);
    assertTrue(winnerAtEvenTimestamp != winnerAtOddTimestamp);
  }
}
