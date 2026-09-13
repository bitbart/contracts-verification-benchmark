/// @custom:preghost function reveal1
bool wrong_preimage = hashing(s) != hash0;

/// @custom:postghost function reveal1
assert(!wrong_preimage);
