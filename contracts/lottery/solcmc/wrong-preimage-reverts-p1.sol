// If a `reveal1(s)` transaction does not revert, then `s` is a preimage of the
// hash committed by `player1`

/// @custom:preghost function reveal1
bool wrong_preimage = hashing(s) != hash1;

/// @custom:postghost function reveal1
assert(!wrong_preimage);
