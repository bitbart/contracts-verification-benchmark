// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "target/CallVerifier_v1.sol";

interface IHalmosVM {
    function load(address target, bytes32 slot) external view returns (bytes32);
}

contract CallVerifierTest {
    CallVerifier cv;

    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function setUp() public {
        cv = new CallVerifier();
    }

    // Proprietà 2: call-success (ground-truth = 0)
    function check_call_success(address a) public {
        cv.f(a);
        bool success = vm.load(address(cv), bytes32(uint256(1))) != bytes32(0); 
        assert(success == true);
    }

}