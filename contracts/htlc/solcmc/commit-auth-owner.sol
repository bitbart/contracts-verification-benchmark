// If `commit()` is successful, then `msg.sender` must be the contract's owner

/// @custom:postghost function commit
assert(msg.sender == owner);