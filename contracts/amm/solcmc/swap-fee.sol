
    function check_swap_fee(address t, uint xIn, uint xOutMin) public {
        uint _r0 = r0;
        uint _r1 = r1;
        
        require(_r0 > 0 && _r1 > 0);
        require(xIn > 0);
        
        
        uint kBefore = _r0 * _r1;

        swap(t, xIn, xOutMin);
        
        uint kAfter = r0 * r1;
        assert(kAfter > kBefore);
    }
