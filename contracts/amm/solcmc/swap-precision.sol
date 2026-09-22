
    function check_swap_precision(address tokenIn, uint xIn) public {

        require(tokenIn == address(t0) || tokenIn == address(t1));
        
        
        uint balanceBefore = (tokenIn == address(t0)) ? t1.balanceOf(address(this)) : t0.balanceOf(address(this));
        

        swap(tokenIn, xIn, 0);
        
        uint balanceAfter = (tokenIn == address(t0)) ? t1.balanceOf(address(this)) : t0.balanceOf(address(this));
        
        assert(balanceAfter < balanceBefore);
    }
