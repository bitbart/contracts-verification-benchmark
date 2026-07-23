// If `reveal()` is successful, it must completely drain the contract's balance

/// @custom:preghost function reveal
require(address(this) != owner);
require(address(this).balance >= fee);

/// @custom:postghost function reveal
assert(address(this).balance == 0);