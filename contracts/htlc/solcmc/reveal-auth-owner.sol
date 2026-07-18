// If `reveal` is successfully called, then the sender must be the owner

/// @custom:postghost function reveal
assert(msg.sender == owner);
