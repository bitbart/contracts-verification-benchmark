// After a non-reverting `win` transaction the contract balance is zero

/// @custom:postghost function win
assert(address(this).balance == 0);
