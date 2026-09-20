
    function check_price_bounds() public view {
        if (r0 > r1) {
            uint p0 = this.price(address(t0));
            uint p1 = this.price(address(t1));
            
            assert(p1 > p0);
        }
    }
