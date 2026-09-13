// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v8.sol";

contract LotteryTest is Test {
  Lottery lottery;

  function setUp() public {
    lottery = new Lottery();
  }
  function test_status_irreversible() public {
    Lottery.Status pre_status = lottery.status();

    lottery.hashing("");

    assertEq(uint8(lottery.status()), uint8(pre_status));
  }
}
