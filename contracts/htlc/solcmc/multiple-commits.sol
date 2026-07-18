// It is possible to successfully call `commit` no more than once
/// @custom:ghost
uint256 _commit_counter;

/// @custom:postghost function commit
_commit_counter += 1;

/// @custom:invariant
function invarint() public view {
    assert(_commit_counter <= 1);
}