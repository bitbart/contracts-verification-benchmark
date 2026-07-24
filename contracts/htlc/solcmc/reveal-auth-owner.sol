// If `reveal()` is successful, then `msg.sender` must be the contract's owner

/// @custom:postghost function reveal
assert(msg.sender == owner);
