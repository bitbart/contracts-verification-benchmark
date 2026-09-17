// After a non-reverting `redeem0_noreveal1` transaction the contract balance is zero

/// @custom:postghost function redeem0_noreveal1
assert(address(this).balance == 0);
