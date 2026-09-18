
    function check_deposit_precision(uint amount0, uint amount1) public {
        uint _r0 = r0;
        uint _r1 = r1;
        uint _supply = supply;

        require(_r0 >= 1000 && _r1 >= 1000);

        // The user deposits at least 1/1000th of the reserves.
        require(amount0 * 1000 >= _r0);
        require(amount1 * 1000 >= _r1);

        // (Removed proportionality precondition to let the prover test if the contract enforces it)
        deposit(amount0, amount1);

        uint newSupply = supply;
        uint mintedTokens = newSupply - _supply;

        // Precision loss should not truncate the minted tokens to zero
        assert(mintedTokens > 0);

        // (amount0 / _r0) * _supply
        assert(mintedTokens * _r0 <= amount0 * _supply);
        // (amount1 / _r1) * _supply
        assert(mintedTokens * _r1 <= amount1 * _supply);
    }
