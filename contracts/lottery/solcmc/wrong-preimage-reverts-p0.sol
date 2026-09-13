/// @custom:preghost function reveal0
bool wrong_preimage = hashing(s) != hash0;

/// @custom:postghost function reveal0
assert(!wrong_preimage);
