/// @custom:negate
rule hash_negate {
    env e;
    string s1;
    string s2;

    require(!strEqual(e, s1, s2));

    bytes32 hash1 = hashing(e, s1);
    bytes32 hash2 = hashing(e, s2);

    require(hash1 == hash2);

    assert(false);
}
