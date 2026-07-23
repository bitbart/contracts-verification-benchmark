// If `commit()` is successful, then `msg.value` is greater than or equal to `fee`

/// @custom:postghost function commit
assert(msg.value >= fee);