rule commit_twice_reverts {
    env e;

    require currentContract.isCommitted;

    bytes32 hash;
    commit@withrevert(e, hash);

    assert lastReverted;
}
