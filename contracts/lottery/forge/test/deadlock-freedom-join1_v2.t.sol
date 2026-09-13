// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v2.sol";

contract LotteryTest is Test {
  Lottery lottery;
  address p0 = makeAddr("p0");
  uint bet = 0.01 ether;

  string s0 = "a";
  bytes32 h0;
  
  function setUp() public {
    lottery = new Lottery();
    vm.deal(p0, 1 ether);
    h0 = lottery.hashing(s0);
  }

  function test_deadlock_freedom_join1() public {
    vm.prank(p0);
    lottery.join0{value: bet}(h0);

    assertTrue(lottery.status() == Lottery.Status.Join1);
    assertEq(address(lottery).balance, bet);

    uint256 p0BalanceBefore = p0.balance;

    vm.roll(lottery.end_join() + 1);
    vm.prank(p0);
    lottery.redeem0_nojoin1();

    assertEq(p0.balance, p0BalanceBefore + bet/2);
    assertEq(address(lottery).balance, bet/2);
    assertTrue(lottery.status() == Lottery.Status.End);
  }
}
