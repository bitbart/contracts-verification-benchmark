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
    address user = address(0x1234);
    address attacker = address(0x5678);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV1 = new V1.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(user, 100000);
        token1.transfer(user, 100000);
        token0.transfer(attacker, 20000);

        vm.prank(user);
        token0.approve(address(ammV1), type(uint256).max);
        vm.prank(user);
        token1.approve(address(ammV1), type(uint256).max);
        
        vm.prank(attacker);
        token0.approve(address(ammV1), type(uint256).max);
    }

    // swap-precision:
    // After a non-reverting `swap` transaction where `amountIn` is strictly positive and the minimum return is set to zero, the contract's balance of the output token is decreased.

    // PoC:
    // - Step 1 (setup): The user deposits massive liquidity, creating a large denominator.
    // - Step 2 (attack): The attacker swaps a microscopic amount (1 wei). Due to integer division truncation, the output evaluates to 0, absorbing the input without returning any value.
    function test_swap_precision_zero_return_v1() public {
        vm.startPrank(user);
        ammV1.deposit(10000, 10000);
        vm.stopPrank();

        uint bal1Before = token1.balanceOf(attacker);
        
        vm.startPrank(attacker);
        ammV1.swap(address(token0), 1, 0); // 1 wei swap
        vm.stopPrank();
        
        uint bal1After = token1.balanceOf(attacker);
        
        assertEq(bal1After - bal1Before, 0);
    }
}
