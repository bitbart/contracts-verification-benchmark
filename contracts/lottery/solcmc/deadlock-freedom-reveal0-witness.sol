// After a non-reverting `redeem1_noreveal0` transaction the contract balance is zero

/// @custom:postghost function redeem1_noreveal0
assert(address(this).balance == 0);
