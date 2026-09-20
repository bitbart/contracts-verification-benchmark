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

contract RedeemLivenessV6Test is Test {
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

    // redeem-liveness:
    // Let `b0`, `b1` be the token balances of the contract, and let `r0`, `r1` be the internal reserves of the contract. If `r0 == b0` and `r1 == b1`, a `redeem(x)` transaction by a sender `A`, with `minted[A] >= x`, `x > 0` and `x < supply` never reverts.

    // PoC:
    // - Step 1 (setup): The user initializes the pool by depositing liquidity. Since V6 removes the `MINIMUM_LIQUIDITY` lock, the user correctly receives 100% of the total supply.
    // - Step 2 (attack): The user attempts to redeem their shares. Since they hold the entire supply (`x == supply`), the transaction reverts strictly due to the flawed `require(x < supply)` check, successfully freezing the last provider's funds.
    function test_redeem_liveness_bug_v6() public {
        vm.startPrank(user);
        ammV6.deposit(10000, 10000);

        uint userShares = ammV6.minted(user);

        vm.expectRevert();
        ammV6.redeem(userShares);
        vm.stopPrank();
    }
}
