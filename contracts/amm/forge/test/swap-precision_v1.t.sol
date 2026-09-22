// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "versions/AMM_v1.sol" as V1;
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

contract SwapPrecisionV1Test is Test {
    V1.AMM ammV1;
    MockToken token0;
    MockToken token1;
    address user = address(0x1111);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV1 = new V1.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(user, 100000);
        token1.transfer(user, 100000);

        vm.startPrank(user);
        token0.approve(address(ammV1), type(uint256).max);
        token1.approve(address(ammV1), type(uint256).max);
        ammV1.deposit(10000, 10000);
        vm.stopPrank();
    }

    // swap-precision:
    // Let `t0`, `t1` be two different tokens held by the contract. After a non-reverting `swap(t0, x_in, x_out_min)` transaction where `x_out_min == 0`, the contract's balance of `t1` is decreased.

    // PoC:
    // - Step 1: Initial liquidity is provided.
    // - Step 2: The user performs a swap by sending exactly 1 wei of `token0`.
    // - Step 3: Due to EVM integer division truncation, the calculated output amount evaluates to 0. The transaction succeeds, but the user receives 0 `token1`, violating the strict increase invariant.
    function test_swap_precision_v1() public {
        uint balOutBefore = token1.balanceOf(user);
        
        vm.startPrank(user);
        ammV1.swap(address(token0), 1, 0); 
        vm.stopPrank();

        uint balOutAfter = token1.balanceOf(user);
        
        assertEq(balOutAfter - balOutBefore, 0);
    }
}
