// After a successful call to `commit()`, the contract's balance must be equal to `msg.value`

/// @custom:preghost function commit
require(address(this) != owner);
require(owner != verifier);
require(msg.sender != address(this));

/// @custom:postghost function commit
assert(address(this).balance == msg.value);