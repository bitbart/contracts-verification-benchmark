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

contract MinimumLiquidityV4Test is Test {
    V6.AMM ammV6;
    MockToken token0;
    MockToken token1;
    address user = address(0x1234);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV6 = new V6.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(user, 10000);
        token1.transfer(user, 10000);

        vm.startPrank(user);
        token0.approve(address(ammV6), type(uint256).max);
        token1.approve(address(ammV6), type(uint256).max);
        vm.stopPrank();
    }

    // minimum-liquidity:
    // If the total supply of liquidity tokens is strictly positive, then `minted[address(0)] >= 1000`.

    // PoC:
    // - Step 1 (setup): The user prepares to deposit initial liquidity into an empty pool.
    // - Step 2 (attack): The user deposits liquidity, but the protocol fails to permanently lock MINIMUM_LIQUIDITY to address(0). As a result, the first depositor retains 100% of the LP supply, leaving the pool vulnerable to share ratio manipulation (Inflation Attack).
    function test_no_minimum_liquidity_lock_v6() public {
        vm.startPrank(user);
        ammV6.deposit(1000, 1000);
        vm.stopPrank();

        uint lockedLiquidity = ammV6.minted(address(0));

        assertEq(lockedLiquidity, 0);

        assertEq(ammV6.minted(user), ammV6.supply());
    }
}
