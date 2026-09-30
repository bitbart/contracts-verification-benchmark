// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "versions/AMM_v3.sol" as V3;
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

contract ReservesNotDrainedV3Test is Test {
    V3.AMM ammV3;
    MockToken token0;
    MockToken token1;
    address user = address(0x1111);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV3 = new V3.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(user, 10000);
        token1.transfer(user, 10000);

        vm.startPrank(user);
        token0.approve(address(ammV3), type(uint256).max);
        token1.approve(address(ammV3), type(uint256).max);
        vm.stopPrank();
    }

    // reserves-not-drained:
    // If `r0 > 0` and `r1 > 0`, then after any non-reverting transaction to the contract, `r0 > 0` and `r1 > 0`.

    // PoC:
    // - Step 1: User deposits initial liquidity into an empty pool.
    // - Step 2: Since V3 erroneously removed the initial `MINIMUM_LIQUIDITY` lock, the user correctly receives 100% of the minted pool shares.
    // - Step 3: The user redeems all their shares, successfully withdrawing the entirety of the pool`s tokens and completely draining the reserves to 0.
    function test_reserves_not_drained_v3() public {
        vm.startPrank(user);
        ammV3.deposit(10000, 10000);
        
        assertEq(ammV3.r0(), 10000);
        
        uint shares = ammV3.minted(user);
        ammV3.redeem(shares);
        vm.stopPrank();

        assertEq(ammV3.r0(), 0);
        assertEq(ammV3.r1(), 0);
    }
}
