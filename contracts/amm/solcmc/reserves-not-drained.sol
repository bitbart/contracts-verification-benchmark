
    function check_reserves_not_drained(uint choice, address t, uint xIn, uint xOutMin, uint x0, uint x1, uint x) public {

        require(r0 > 0 && r1 > 0);
        
        
        if (choice == 0) {
            swap(t, xIn, xOutMin);
        }
        else if (choice == 1) {
            deposit(x0, x1);
        }
        else {
            redeem(x);
        }

        assert(r0 > 0 && r1 > 0);
    }
