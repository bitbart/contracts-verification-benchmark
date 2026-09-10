// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./lib/IERC20.sol";

/// @custom:version Fixed Reentrancy & Unsafe transfers

contract AMM {
    IERC20 public immutable t0;
    IERC20 public immutable t1;

    uint public r0;
    uint public r1;

    uint constant MINIMUM_LIQUIDITY = 1000;
    uint public supply;
    mapping(address => uint) public minted;

    uint private unlocked = 1;
    modifier nonReentrant() {
        require(unlocked == 1, "ReentrancyGuard: reentrant call");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(IERC20 _t0, IERC20 _t1) {
        t0 = IERC20(_t0);
        t1 = IERC20(_t1);
        require(address(t0) != address(t1));
    }

    function deposit(uint x0, uint x1) public nonReentrant {
        require (x0>0 && x1>0);

           
        uint toMint;
           
        if (supply > 0) {
            require (r0 > 0);
            require(r0 * x1 == r1 * x0, "Dep precondition");
            toMint = (x0 * supply) / r0;
        }
        else {
            uint liquidity = _sqrt(x0 * x1);
            require(liquidity > MINIMUM_LIQUIDITY, "Dep precondition");
            minted[address(0)] += MINIMUM_LIQUIDITY;
            supply += MINIMUM_LIQUIDITY;
            toMint = liquidity - MINIMUM_LIQUIDITY;
        }
           
        require(toMint > 0, "Dep precondition");
           
        minted[msg.sender] += toMint;
        supply += toMint;
        r0 += x0;
        r1 += x1;
        _safeTransferFrom(t0, msg.sender, address(this), x0);
        _safeTransferFrom(t1, msg.sender, address(this), x1);
    }

    function redeem(uint x) public nonReentrant {
        require (supply > 0);
        require (minted[msg.sender] >= x);

        uint x0 = (x * r0) / supply;
        uint x1 = (x * r1) / supply;
            
        r0 -= x0;
        r1 -= x1;
        supply -= x;
        minted[msg.sender] -= x;
        _safeTransfer(t0, msg.sender, x0);
        _safeTransfer(t1, msg.sender, x1);
    }

    function swap(address t, uint x_in, uint x_out_min) public nonReentrant {
	require(t == address(t0) || t == address(t1));
        require(x_in > 0);

        bool is_t0 = t == address(t0);
        (IERC20 t_in, IERC20 t_out, uint r_in, uint r_out) = is_t0
            ? (t0, t1, r0, r1)
            : (t1, t0, r1, r0);
	
	
        uint amountInWithFee = x_in * 997;
        uint numerator = amountInWithFee * r_out;
        uint denominator = (r_in * 1000) + amountInWithFee;
        uint x_out = numerator / denominator;

        require(x_out >= x_out_min);
	
        (r0,r1) = is_t0
            ? (r0 + x_in, r1 - x_out)
            : (r0 - x_out, r1 + x_in);
        _safeTransferFrom(t_in, msg.sender, address(this), x_in);
        _safeTransfer(t_out, msg.sender, x_out);
        

    }

    function _safeTransfer(IERC20 token, address to, uint value) private {
        require(token.transfer(to, value));
    }

    function _safeTransferFrom(IERC20 token, address from, address to, uint value) private {
        require(token.transferFrom(from, to, value));
    }

    function _sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        }
        else if (y != 0) {
            z = 1;
        }
    }

    function price(address token) external view returns (uint) {
        if (token == address(t0)) {
            require(r0 > 0, "no reserves");
            return (r1 * 1e18) / r0;
        } else if (token == address(t1)) {
            require(r1 > 0, "no reserves");
            return (r0 * 1e18) / r1;
        }
        revert("invalid token");
    }
}
