
    function check_deposit_precision(uint x0, uint x1) public {
        
        uint supplyBefore = supply;

        require(x0 * 1000 >= r0);
        require(x1 * 1000 >= r1);


        deposit(x0, x1);


        uint minted = supply - supplyBefore;

        assert(minted > 0);
        assert(minted * r0 <= x0 * supply);
        assert(minted * r1 <= x1 * supply);
    }
