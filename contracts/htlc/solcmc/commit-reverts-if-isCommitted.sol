// If contract is already in a committed state, then any following `commit()` calls must revert

/// @custom:preghost function commit
bool _wasCommitted = isCommitted;

/// @custom:postghost function commit
assert(!_wasCommitted);