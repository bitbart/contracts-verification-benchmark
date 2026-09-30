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

contract ConstantProductReservesV6Test is Test {
    V6.AMM ammV6;
    MockToken token0;
    MockToken token1;
    address user = address(0x1337);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV6 = new V6.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.approve(address(ammV6), type(uint256).max);
        token1.approve(address(ammV6), type(uint256).max);
        ammV6.deposit(100, 100);

        token0.transfer(user, 1000);
    }

    // constant-product-reserves:
    // After a non-reverting `swap(t, x_in, x_out_min)` transaction, the product between `r0` and `r1` after the transaction is greater than or equal to their product before the transaction, where `r0` and `r1` are the token internal reserves of the contract.

    // PoC:
    // - Step 1: Initial liquidity is provided (100 token0, 100 token1).
    // - Step 2: User performs a normal swap.
    // - Step 3: Due to the flawed linear formula `x_out = (x_in * r_out) / r_in` in V6, the output is over-calculated. This inherently causes the mathematical product of the reserves to strictly decrease.
    function test_constant_product_reserves_broken_v6() public {
        uint productBefore = ammV6.r0() * ammV6.r1();

        vm.startPrank(user);
        token0.approve(address(ammV6), type(uint256).max);
        ammV6.swap(address(token0), 50, 0);
        vm.stopPrank();

        uint productAfter = ammV6.r0() * ammV6.r1();
        
        assertLt(productAfter, productBefore);
    }
}
