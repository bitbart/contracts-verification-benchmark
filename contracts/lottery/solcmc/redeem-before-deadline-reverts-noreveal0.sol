/// @custom:preghost function redeem1_noreveal0
bool _valid_redeem1_noreveal0 = block.number > end_reveal0;

/// @custom:postghost function redeem1_noreveal0
assert(_valid_redeem1_noreveal0);
