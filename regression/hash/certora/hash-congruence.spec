/// @custom:run certoraRun Hashing_v1.sol:Hashing --verify Hashing:certora/hash-congruence.spec --optimistic_loop

rule hash_congruence {
    env e;
    string s1;
    string s2;

    require(strEqual(e, s1, s2));

    bytes32 hash1 = hashing(e, s1);
    bytes32 hash2 = hashing(e, s2);

    assert(hash1 == hash2);
}
