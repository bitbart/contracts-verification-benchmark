// If a `reveal0(s)` transaction does not revert, then `s` is a preimage of the
// hash committed by `player0`

/// @custom:preghost function reveal0
bool wrong_preimage = hashing(s) != hash0;

/// @custom:postghost function reveal0
assert(!wrong_preimage);
