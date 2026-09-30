
    function check_redeem_precision(uint x) public {
        
        require(x > 0);
        require(x <= minted[msg.sender]);
        require(x <= supply);
        require(supply > 0);

        uint bal0Before = t0.balanceOf(msg.sender);
        uint bal1Before = t1.balanceOf(msg.sender);

        redeem(x);

        uint bal0After = t0.balanceOf(msg.sender);
        uint bal1After = t1.balanceOf(msg.sender);

        assert(bal0After > bal0Before);
        assert(bal1After > bal1Before);
    }
