// SPDX-License-Identifier: GPL-3.0-only

// Attemps to call `reveal()` with wrong preimage of committed hash should revert

methods {
    function hashing(string s) external returns(bytes32) envfree;
}

rule wrong_preimage_reverts {
    env e;
    string s;
    require hashing(s) != currentContract.hash;
    reveal@withrevert(e, s);
    assert lastReverted;
}