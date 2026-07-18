// If `commit` is called successfully, then msg.value should be at least `fee`
/// @custom:postghost function commit
assert(msg.value >= fee);