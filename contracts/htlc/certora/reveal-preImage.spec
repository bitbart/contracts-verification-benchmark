// SPDX-License-Identifier: GPL-3.0-only

// If `reveal(s)` does not revert, then `s` is a preimage of the committed hash

rule reveal_preimage {
    env e1;
    bytes32 h;
    commit@withrevert(e1, h);
    require !lastReverted;

    env e2;
    string s;
    reveal(e2, s);
    
    assert (hashing(e2, s) == h);
}