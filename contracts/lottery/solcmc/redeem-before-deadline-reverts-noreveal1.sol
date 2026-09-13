/// @custom:preghost function redeem0_noreveal1
bool _valid_redeem0_noreveal1 = block.number > end_reveal1;

/// @custom:postghost function redeem0_noreveal1
assert(_valid_redeem0_noreveal1);
