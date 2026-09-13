/// @custom:preghost function reveal0
bool _valid_reveal0 = block.number <= end_reveal0;

/// @custom:postghost function reveal0
assert(_valid_reveal0);
