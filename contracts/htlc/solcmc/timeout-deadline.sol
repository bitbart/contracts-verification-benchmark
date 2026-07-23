// If `timeout()` is successful, the transaction must have occurred at a block number greater than or equal to the contract's initial block plus `waitTime`

/// @custom:postghost function timeout
assert (block.number >= start + waitTime);
