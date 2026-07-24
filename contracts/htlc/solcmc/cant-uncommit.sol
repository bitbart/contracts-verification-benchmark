// If contract is in a committed state, no function should be able to reverse it back to an uncommitted state

/// @custom:ghost
bool _wasCommitted;

/// @custom:invariant
function invariant() internal {
    if (_wasCommitted) {
        assert(isCommitted);
    }
    _wasCommitted = isCommitted;
}