
    function check_swap_slippage(address t, uint xIn, uint xOutMin) public {
        
        require(t == address(t0) || t == address(t1));
        
     
        uint balanceOutBefore = t == address(t0) ? t1.balanceOf(msg.sender) : t0.balanceOf(msg.sender);
        
        swap(t, xIn, xOutMin);
        
        uint balanceOutAfter = t == address(t0) ? t1.balanceOf(msg.sender) : t0.balanceOf(msg.sender);
        
        assert(balanceOutAfter >= balanceOutBefore + xOutMin);
    }
