/// @custom:property minimum-liquidity-strict
/// @custom:description If the total supply of liquidity tokens is strictly positive, the amount of liquidity tokens minted to the zero address is always equal to 1000.

invariant minimum_liquidity_strict(env e)
    currentContract.supply(e) > 0 => currentContract.minted(e, 0) == 1000
    {
        preserved {
            require e.msg.sender != 0;
        }
    }
