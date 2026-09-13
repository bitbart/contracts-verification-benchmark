
    function check_price_symmetry() public view {
        if (r0 > 0 && r1 > 0 && t0 != t1) {
            uint p0 = this.price(address(t0));
            uint p1 = this.price(address(t1));
            
            assert(p0 * p1 <= 1e36);
        }
    }
