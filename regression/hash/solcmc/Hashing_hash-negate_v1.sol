// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Hashing {
	function hashing(string memory s) pure public returns (bytes32) {
		return keccak256(abi.encodePacked(s));
	}

	function strEqual(string memory a, string memory b) public pure returns (bool) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        if (ba.length != bb.length) return false;
        for (uint i = 0; i < ba.length; i++) {
            if (ba[i] != bb[i]) return false;
        }
        return true;
    }
	
    /// @custom:negate
	function g(string memory s1, string memory s2) public pure {
    require(!strEqual(s1, s2));
    require(hashing(s1) == hashing(s2));
    assert(false); // If this assertion is reached, then a collision has been found
	}
}

