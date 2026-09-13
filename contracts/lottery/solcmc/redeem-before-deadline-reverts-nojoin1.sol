/// @custom:preghost function redeem0_nojoin1
bool _valid_redeem0_nojoin1 = block.number > end_join;

/// @custom:postghost function redeem0_nojoin1
assert(_valid_redeem0_nojoin1);
