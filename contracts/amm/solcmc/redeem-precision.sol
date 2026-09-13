
    function check_redeem_precision(uint shares) public {
        require(shares > 0);
        require(shares <= minted[msg.sender]);
        require(shares <= supply);
        require(supply > 0);

        require(msg.sender != address(0));
        require(msg.sender != address(this));
        require(msg.sender != address(t0) && msg.sender != address(t1));

        uint bal0Before = t0.balanceOf(msg.sender);
        uint bal1Before = t1.balanceOf(msg.sender);

        redeem(shares);

        uint bal0After = t0.balanceOf(msg.sender);
        uint bal1After = t1.balanceOf(msg.sender);

        assert(bal0After > bal0Before);
        assert(bal1After > bal1Before);
    }
