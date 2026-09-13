
    function check_redeem_liveness(uint shares) public {
        uint bal0 = t0.balanceOf(address(this));
        uint bal1 = t1.balanceOf(address(this));
        
        require(bal0 == r0 && bal1 == r1);
        require(shares > 0 && shares <= minted[address(this)]);
        require(supply > 0);
        
        (bool success, ) = address(this).call(abi.encodeWithSignature("redeem(uint256)", shares));
        assert(success);
    }
