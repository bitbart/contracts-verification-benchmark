/// @custom:property minimum-liquidity
/// @custom:description If the total supply of liquidity tokens is strictly positive, the amount of liquidity tokens minted to the zero address is always greater than or equal to 1000.

invariant minimum_liquidity(env e)
    currentContract.supply(e) > 0 => currentContract.minted(e, 0) >= 1000
    {
        preserved {
            require e.msg.sender != 0;
        }
    }
