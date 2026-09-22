
    function check_donation_dos(uint x) public {
        
        uint b0 = t0.balanceOf(address(this));
        uint b1 = t1.balanceOf(address(this));
        
        require(b0 >= r0 && b1 >= r1);
        require(minted[address(this)] >= x);
        require(supply > 0);
        require(x <= supply);
        
        (bool success, ) = address(this).call(abi.encodeWithSignature("redeem(uint256)", x));
        assert(success);
    }
