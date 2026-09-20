
    function check_swap_fee_gt0(address t, uint xIn, uint xOutMin) public {
        
        require(r0 > 0 && r1 > 0);
        
        uint kBefore = r0 * r1;
        

        swap(t, xIn, xOutMin);
        
        
        uint kAfter = r0 * r1;

        assert(kAfter > kBefore);
    }
