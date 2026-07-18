// If `isCommitted` is true, then calling `commit` reverts
// This rule is actually stating the opposite property: "if commit does not revert, then isCommitted was false

/// @custom:ghost
bool _isCommitted_before;

/// @custom:preghost function commit
_isCommitted_before = isCommitted;

/// @custom:postghost function commit
assert(!_isCommitted_before);