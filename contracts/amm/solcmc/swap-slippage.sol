
    function check_swap_slippage(address t, uint xIn, uint xOutMin) public {
        require(t == address(t0) || t == address(t1));
        
        require(msg.sender != address(0));
        require(msg.sender != address(this));
        require(msg.sender != address(t0) && msg.sender != address(t1));

        bool is_t0 = t == address(t0);
        
        uint balanceOutBefore = is_t0 ? t1.balanceOf(msg.sender) : t0.balanceOf(msg.sender);
        
        swap(t, xIn, xOutMin);
        
        uint balanceOutAfter = is_t0 ? t1.balanceOf(msg.sender) : t0.balanceOf(msg.sender);
        
        assert(balanceOutAfter >= balanceOutBefore + xOutMin);
    }
