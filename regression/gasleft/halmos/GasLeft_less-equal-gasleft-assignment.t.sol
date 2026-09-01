// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import"target/GasLeft_v1.sol";

contract GasLeftTest is GasLeft {
    function check_less_equal_gasleft_assignment() public view {
		uint firtst_gl = gasleft();
        uint second_gl = gasleft();

		assert(second_gl <= firtst_gl);
	}
}