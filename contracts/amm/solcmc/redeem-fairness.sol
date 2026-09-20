
    function check_redeem_fairness(uint x) public {

        require(supply > 0);
        require(minted[msg.sender] >= x);
        require(x > 0);
        


        uint senderBal0Before = t0.balanceOf(msg.sender);
        uint senderBal1Before = t1.balanceOf(msg.sender);
        

        uint expectedOut0 = (x * t0.balanceOf(address(this))) / supply;
        uint expectedOut1 = (x * t1.balanceOf(address(this))) / supply;
        

        redeem(x);
        

        uint senderBal0After = t0.balanceOf(msg.sender);
        uint senderBal1After = t1.balanceOf(msg.sender);
        
        assert(senderBal0After - senderBal0Before == expectedOut0);
        assert(senderBal1After - senderBal1Before == expectedOut1);
    }
