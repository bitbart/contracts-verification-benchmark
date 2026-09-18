// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import"target/Modifiers_v1.sol";

contract ModifiersTest is Modifiers{

    function check_g_modifiers_x() public{
        g();
        assert(x==7);
    }    

}