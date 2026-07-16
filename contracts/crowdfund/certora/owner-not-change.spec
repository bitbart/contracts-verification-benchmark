
/// owner-not-change:
/// the address `owner` does not change after its value is
/// initialized in the constructor.

rule owner_not_change {
    env e;
    calldataarg args;
    method f;

    address old_owner = currentContract.owner;

    f@withrevert(e, args);

    address new_owner = currentContract.owner;

    assert /*!lastReverted => */old_owner == new_owner;
}