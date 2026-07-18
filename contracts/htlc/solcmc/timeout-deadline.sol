//If `timeout` is called, then at least `waitTime` blocks have passed since the contract was deployed.

/// @custom:postghost function timeout
assert (block.number >= start + waitTime);
