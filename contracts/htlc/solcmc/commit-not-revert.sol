// If `commit()` is successful, then isCommitted was false before the call
/// @custom:ghost
bool _isCommitted_before;

/// @custom:preghost function commit
_isCommitted_before = isCommitted;

/// @custom:postghost function commit
assert(!_isCommitted_before);