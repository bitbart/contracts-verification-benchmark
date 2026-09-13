// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;
import { Test } from "forge-std/Test.sol";
import { Lottery } from "../src/Lottery_v14.sol";

contract LotteryTest is Test {
  Lottery lottery;
  address owner = makeAddr("owner");
  address other = makeAddr("other");
  address forcedWinner = makeAddr("forcedWinner");

  function setUp() public {
    vm.prank(owner);
    lottery = new Lottery();
  }
  function test_owner_impartiality_eoa() public {
    assertTrue(lottery.status() == Lottery.Status.Join0);
    assertTrue(lottery.status() == Lottery.Status.Join0);

    uint snapshotId = vm.snapshotState();
    
    vm.prank(owner);
    lottery.forceWinner(payable(forcedWinner));

    assertEq(lottery.winner(), forcedWinner);
    assertTrue(lottery.status() == Lottery.Status.End);

    vm.revertToState(snapshotId);

    vm.prank(other);
    vm.expectRevert();
    lottery.forceWinner(payable(forcedWinner));

    assertEq(lottery.winner(), address(0));
    assertTrue(lottery.status() == Lottery.Status.Join0);
  }
}
