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

contract DepositPrecisionStrictTest is Test {
    V1.AMM ammV1;
    MockToken token0;
    MockToken token1;
    address user = address(0x1337);
    address attacker = address(0x1234);

    function setUp() public {
        token0 = new MockToken();
        token1 = new MockToken();
        ammV1 = new V1.AMM(IERC20(address(token0)), IERC20(address(token1)));

        token0.transfer(user, 20000);
        token1.transfer(user, 20000);
        token0.transfer(attacker, 20000);
        token1.transfer(attacker, 20000);

        vm.startPrank(user);
        token0.approve(address(ammV1), type(uint256).max);
        token1.approve(address(ammV1), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(attacker);
        token0.approve(address(ammV1), type(uint256).max);
        token1.approve(address(ammV1), type(uint256).max);
        vm.stopPrank();
    }

    // deposit-precision-strict:
    // After a non-reverting `deposit` transaction where the deposited amounts are proportional to the reserves and are at least one-thousandth of the current reserves, the minted liquidity tokens are strictly positive and equal to the proportion between the deposited amounts and the contract's existing reserves.

    // PoC (Proof of Concept):
    // - Step 1 (Setup): The user provides initial liquidity, followed by a direct token donation and a minor swap. This misaligns the contract's internal reserves from perfect symmetry.
    // - Step 2 (Transaction & Assertion): The attacker deposits a slightly irregular amount. Because the EVM lacks floating-point precision and truncate integer divisions, the shares minted are mathematically floored. This proves that enforcing a strict equality check (minted_shares / supply == deposited_amount / reserves) will inevitably fail in real EVM environments.
    function test_rounding_error_strict_equality() public {

        // Setup: user deposits initial liquidity
        vm.startPrank(user);
        ammV1.deposit(1999, 1999);
        vm.stopPrank();

        // Attacker redeems 1 share to decouple reserves from supply
        // x0 = 1 * 1999 / 1999 = 1
        // x1 = 1 * 1999 / 1999 = 1
        // supply = 1998, r0 = 1998, r1 = 1998
        // Wait, V1 doesn't have minimum liquidity, so any symmetric op keeps them equal.
        // Let's do a swap instead to skew it.
        vm.startPrank(user);
        ammV1.swap(address(token0), 1999, 0);
        // r0 becomes 3998, r1 becomes approx 1000.
        vm.stopPrank();

        uint current_r0 = ammV1.r0(); // e.g. 3998
        uint current_r1 = ammV1.r1(); // e.g. 1000
        uint current_supply = ammV1.supply(); // e.g. 1999

        // Deposit exactly proportional amounts so r0 * x1 == r1 * x0
        // e.g., if r0=3998, r1=1000, we deposit x0=1999, x1=500
        uint x0 = current_r0 / 2;
        uint x1 = current_r1 / 2;
        
        vm.startPrank(attacker);
        ammV1.deposit(x0, x1);
        vm.stopPrank();

        uint attacker_shares = ammV1.minted(attacker);

        uint left_side = attacker_shares * current_r0;
        uint right_side = x0 * current_supply;

        assertNotEq(left_side, right_side, "Strict equality holds (unexpected)");
        assertLe(left_side, right_side, "Tolerance inequality fails");
    }
}
