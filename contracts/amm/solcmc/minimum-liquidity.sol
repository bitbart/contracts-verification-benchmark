
    function check_minimum_liquidity() public view {
        if (supply > 0) {
            assert(minted[address(0)] >= 1000);
        }
    }
