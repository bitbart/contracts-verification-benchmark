
    function check_price_bounds() public view {
        if (r1 > 0 && r0 > r1 && t0 != t1) {
            uint p0 = this.price(address(t0));
            uint p1 = this.price(address(t1));
            
            assert(p1 > p0);
        }
    }
