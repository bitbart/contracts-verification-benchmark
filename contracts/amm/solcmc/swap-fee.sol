
    function check_swap_fee(address t, uint xIn, uint xOutMin) public {

        
        uint kBefore = r0 * r1;
        

        swap(t, xIn, xOutMin);
        

        uint kAfter = r0 * r1;

        assert(kAfter > kBefore);
    }
