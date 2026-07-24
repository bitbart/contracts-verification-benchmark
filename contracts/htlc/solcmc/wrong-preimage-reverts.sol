// If a `reveal(s)` transaction does not revert, then `s` is a preimage of the committed hash

/// @custom:preghost function reveal
bool _is_preImage_same = hashing(s) != hash;

/// @custom:postghost function reveal
assert(!_is_preImage_same);