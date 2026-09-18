
    function check_reserves_not_drained(uint choice, address t, uint xIn, uint xOutMin, uint x0, uint x1, uint shares) public {
        uint _r0 = r0;
        uint _r1 = r1;
        
        require(_r0 > 0 && _r1 > 0);
        require(t0.balanceOf(address(this)) >= _r0);
        require(t1.balanceOf(address(this)) >= _r1);
        
        require(t0 != t1);
        require(supply > 0);
        require(minted[msg.sender] < supply);

        
        if (choice == 0) {
            swap(t, xIn, xOutMin);
        }
        else if (choice == 1) {
            deposit(x0, x1);
        }
        else {
            redeem(shares);
        }

        assert(r0 > 0 && r1 > 0);
    }
