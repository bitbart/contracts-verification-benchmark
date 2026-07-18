// SPDX-License-Identifier: GPL-3.0-only

// If `reveal()` does not revert, then the revealed string is a preimage of the committed hash

rule reveal_preimage {
    env e1;
    bytes32 h;
    commit(e1, h);

    env e2;
    string s;
    reveal(e2, s);
    
    assert (hashing(e2, s) == h);
}

// certora assumes no collisions

// regression/hash
// string -> commit -> reveal string.
// If success revealed string should be equal to stored string
