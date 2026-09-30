
    function check_constant_product(address t, uint xIn, uint xOutMin) public {
    
        uint oldK = t0.balanceOf(address(this)) * t1.balanceOf(address(this));
        
        swap(t, xIn, xOutMin);

        uint newK = t0.balanceOf(address(this)) * t1.balanceOf(address(this));
        
        assert(newK >= oldK);

    }
