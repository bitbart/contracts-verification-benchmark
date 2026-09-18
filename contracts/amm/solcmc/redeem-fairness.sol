
    function check_redeem_fairness(uint x) public {
        uint _supply = supply;
        require(_supply > 0);
        require(x > 0 && x <= minted[msg.sender]);
        
        uint bal0Before = t0.balanceOf(address(this));
        
        uint expectedOut0 = (x * bal0Before) / _supply;
        
        redeem(x);
        
        uint bal0After = t0.balanceOf(address(this));
        
        assert(bal0Before - bal0After == expectedOut0);
    }
