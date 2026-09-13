// ANSWER: FALSE
// EXPLANATION: `win()` is callable when `status == Status.Win`, but after successfully transferring the balance it sets `status = Status.End`, so that transaction increases the status. However, a non-reverting `redeem0_nojoin1()` or other state-changing function is not the only possibility: `hashing()` and `compute_winner()` are public `pure` functions and can be called successfully by an EOA without changing `status`. Thus the property fails because the status is unchanged by these non-reverting transactions.
// COUNTEREXAMPLE: Initial state after deployment has `status == Status.Join0`. An EOA calls `hashing("")`. The call succeeds and does not modify any state, so `status` remains `Status.Join0` (0), rather than becoming strictly greater.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v7.sol";

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
