// After a non-reverting `redeem0_nojoin1` transaction the contract balance is zero

/// @custom:postghost function redeem0_nojoin1
assert(address(this).balance == 0);
