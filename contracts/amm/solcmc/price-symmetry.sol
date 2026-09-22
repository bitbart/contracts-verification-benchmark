
    function check_price_symmetry() public view {
        uint p0 = this.price(address(t0));
        uint p1 = this.price(address(t1));
            
        assert(p0 * p1 <= 1e36);
    }
