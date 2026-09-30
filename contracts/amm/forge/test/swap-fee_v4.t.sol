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

contract SwapFeeV4Test is Test {
    V4.AMM ammV4;
    MockToken token0;
    MockToken token1;
    address user = address(0x1111);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV4 = new V4.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(user, 100000);
        token1.transfer(user, 100000);

        vm.startPrank(user);
        token0.approve(address(ammV4), type(uint256).max);
        token1.approve(address(ammV4), type(uint256).max);
        ammV4.deposit(10000, 10000);
        vm.stopPrank();
    }

    // swap-fee:
    // After a non-reverting `swap(t0, x_in, x_out_min)` transaction, the product of the contract's internal reserves `r0` and `r1`  after the transaction is greater than their product before the transaction.

    // PoC:
    // - Step 1: Initial liquidity is provided.
    // - Step 2: The user performs a swap.
    // - Step 3: V4 implements a zero-fee model (`x_out = (x_in * r_out) / (r_in + x_in)`). When the math division is exact without truncation, the product of the reserves remains exactly constant, violating the strict inequality requirement.
    function test_swap_fee_zero_fee_v4() public {
        uint kBefore = ammV4.r0() * ammV4.r1();

        vm.startPrank(user);
        ammV4.swap(address(token0), 10000, 0);
        vm.stopPrank();

        uint kAfter = ammV4.r0() * ammV4.r1();

        assertEq(kAfter, kBefore);
    }
}
