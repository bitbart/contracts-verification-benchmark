
    function check_price_equality() public view {
        if (r0 == r1 && r0 > 0) {
            uint p0 = this.price(address(t0));
            uint p1 = this.price(address(t1));
            
            assert(p0 == p1);
        }
    }
