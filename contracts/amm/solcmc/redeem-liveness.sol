
    function check_redeem_liveness(uint x) public {
        uint bal0 = t0.balanceOf(address(this));
        uint bal1 = t1.balanceOf(address(this));
        
        require(bal0 == r0 && bal1 == r1);
        
        require(x > 0);
        require(minted[address(this)] >= x);
        require(x < supply);
        
        (bool success, ) = address(this).call(abi.encodeWithSignature("redeem(uint256)", x));
        assert(success);
    }
