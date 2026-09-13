
    function check_swap_precision(address tokenIn, uint amountIn) public {
        uint _r0 = r0;
        uint _r1 = r1;
        
        require(amountIn > 0);
        require(tokenIn == address(t0) || tokenIn == address(t1));
        
        require(_r0 > 0 && _r1 > 0);
        require(t0.balanceOf(address(this)) == _r0);
        require(t1.balanceOf(address(this)) == _r1);
        
        
        uint balanceOutBefore = (tokenIn == address(t0)) ? _r1 : _r0;
        
        swap(tokenIn, amountIn, 0);
        
        uint balanceOutAfter = (tokenIn == address(t0)) ? t1.balanceOf(address(this)) : t0.balanceOf(address(this));
        
        assert(balanceOutAfter < balanceOutBefore);
    }
