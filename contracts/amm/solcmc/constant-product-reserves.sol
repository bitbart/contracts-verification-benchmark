
    function check_constant_product_reserves(address t, uint xIn, uint xOutMin) public {
                
        uint oldK = r0 * r1;
        
        swap(t, xIn, xOutMin);
        
        uint newK = r0 * r1;
        
        assert(newK >= oldK);
    }
