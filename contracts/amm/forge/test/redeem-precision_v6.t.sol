// SPDX-License-Identifier: UNLICENSED
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

contract RedeemPrecisionTest is Test {
    V6.AMM ammV6;
    MockToken token0;
    MockToken token1;

    address user = address(0x1);
    address attacker = address(0x2);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV6 = new V6.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(user, 10000);
        token1.transfer(user, 10000);
        token0.transfer(attacker, 10000);
        token1.transfer(attacker, 10000);

        vm.startPrank(user);
        token0.approve(address(ammV6), type(uint256).max);
        token1.approve(address(ammV6), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(attacker);
        token0.approve(address(ammV6), type(uint256).max);
        token1.approve(address(ammV6), type(uint256).max);
        vm.stopPrank();
    }

    // redeem-precision:
    // After a non-reverting `redeem` transaction of a strictly positive amount of liquidity tokens, the real token balances of the sender strictly increase.

    // PoC:
    // - Step 1 (setup): The user initializes the pool with a large amount of liquidity.
    // - Step 2 (attack): The user attempts to redeem a very small amount of shares. Due to the lack of slippage, the integer division truncates the output to zero, burning the shares without returning any tokens.
    function test_redeem_precision_loss() public {

        vm.startPrank(attacker);
        ammV6.deposit(1000, 1000);
        vm.stopPrank();

        assertEq(ammV6.supply(), 1000);
        assertEq(ammV6.r0(), 1000);

        vm.startPrank(user);
        ammV6.deposit(10, 10);

        uint aliceShares = ammV6.minted(user);
        assertEq(aliceShares, 10);

        uint bal0Before = token0.balanceOf(user);
        ammV6.redeem(1);
        uint bal0After = token0.balanceOf(user);

        assertEq(bal0After - bal0Before, 1);

        vm.stopPrank();
    }
}
