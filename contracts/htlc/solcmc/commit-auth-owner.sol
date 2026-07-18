// If `commit` is successfully called, then the sender must be the owner.

/// @custom:postghost function commit
assert(msg.sender == owner);