// `reveal()` and `timeout()` can only be successfully called if contract is in a committed state

/// @custom:preghost function reveal
bool pre = !isCommitted;

/// @custom:postghost function reveal
assert(!pre);

/// @custom:preghost function timeout
bool pre = !isCommitted;

/// @custom:postghost function timeout
assert(!pre);
