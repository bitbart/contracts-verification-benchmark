
    function check_constant_product_reserves(address tokenIn, uint amountIn, uint amountOutMin) public {
        uint bal0Before = r0;
        uint bal1Before = r1;
        
        require(amountIn > 0 && amountIn < 1000000);
        require(tokenIn == address(t0) || tokenIn == address(t1));
        
        require(bal0Before > 0 && bal1Before > 0);
        require(bal0Before < 1000000 && bal1Before < 1000000);
        
        uint oldK = bal0Before * bal1Before;
        
        swap(tokenIn, amountIn, amountOutMin);
        
        uint bal0After = r0;
        uint bal1After = r1;
        uint newK = bal0After * bal1After;
        
        assert(newK >= oldK);
    }
