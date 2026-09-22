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

contract RedeemFairnessV1Test is Test {
    V1.AMM ammV1;
    MockToken token0;
    MockToken token1;
    address user = address(0x1111);
    address attacker = address(0x2222);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV1 = new V1.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(user, 10000);
        token1.transfer(user, 10000);
        token0.transfer(attacker, 10000);

        vm.startPrank(user);
        token0.approve(address(ammV1), type(uint256).max);
        token1.approve(address(ammV1), type(uint256).max);
        ammV1.deposit(10000, 10000);
        vm.stopPrank();
    }

    // redeem-fairness:
    // After a non-reverting `redeem(x)` transaction, the balances of tokens `t0` and `t1` held by the sender must increase respectively by exactly `(x * b0) / supply` and `(x * b1) / supply`, where `b0` and `b1` are the contract's actual token balances before the transaction.

    // PoC:
    // - Step 1: User deposits initial liquidity.
    // - Step 2: Attacker donates tokens directly to the AMM, increasing the real token balance `b0` without updating the internal reserve `r0`.
    // - Step 3: Because V1`s `redeem` function uses the internal reserve `r0` instead of the real balance `b0` for calculating payouts, the user receives fewer tokens than their fair share of the actual pool balance.
    function test_redeem_fairness_v1() public {
        vm.startPrank(attacker);
        token0.transfer(address(ammV1), 5000);
        vm.stopPrank();

        uint initialSupply = ammV1.supply(); 
        uint initialBal0 = token0.balanceOf(address(ammV1));
        
        vm.startPrank(user);
        uint userShares = ammV1.minted(user);
        uint bal0Before = token0.balanceOf(user);
        
        uint expectedOut0 = (userShares * initialBal0) / initialSupply;
        
        ammV1.redeem(userShares);
        
        uint bal0After = token0.balanceOf(user);
        uint actualOut0 = bal0After - bal0Before;
        vm.stopPrank();
        
        assertLt(actualOut0, expectedOut0);
    }
}
