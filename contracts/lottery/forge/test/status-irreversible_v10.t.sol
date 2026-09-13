// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v10.sol";

contract LotteryTest is Test {
  Lottery lottery;

  function setUp() public {
    lottery = new Lottery();
  }
  function test_status_irreversible() public {
    lottery.win();
    assertTrue(lottery.status() == Lottery.Status.End);

    lottery.win();

    assertTrue(lottery.status() == Lottery.Status.End);
  }
}
