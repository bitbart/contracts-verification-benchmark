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

contract ConstantProductV6Test is Test {
    V6.AMM ammV6;
    MockToken token0;
    MockToken token1;
    address attacker = address(0x1337);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV6 = new V6.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.approve(address(ammV6), type(uint256).max);
        token1.approve(address(ammV6), type(uint256).max);
        ammV6.deposit(100, 100);

        token0.transfer(attacker, 1000);
    }

    // constant-product:
    // After a non-reverting `swap(t, x_in, x_out_min)` transaction, the product between `b0` and `b1` after the transaction is greater than or equal to their product before the transaction, where `b0` and `b1` are the token balances of the contract.

    // PoC:
    // - Step 1: Initial liquidity is provided.
    // - Step 2: The attacker performs a normal swap.
    // - Step 3: Because V6 uses a flawed linear formula `x_out = (x_in * r_out) / r_in`, the output is much larger than it should be. This causes the mathematical product of the reserves to strictly decrease, violating the property.
    function test_broken_math_constant_product_v6() public {
        uint productBefore = token0.balanceOf(address(ammV6)) * token1.balanceOf(address(ammV6));

        vm.startPrank(attacker);
        token0.approve(address(ammV6), type(uint256).max);
        ammV6.swap(address(token0), 50, 0);
        vm.stopPrank();

        uint productAfter = token0.balanceOf(address(ammV6)) * token1.balanceOf(address(ammV6));
        
        assertLt(productAfter, productBefore);
    }
}
