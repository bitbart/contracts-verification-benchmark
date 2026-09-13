/// @custom:preghost function reveal1
bool _valid_reveal1 = block.number <= end_reveal1;

/// @custom:postghost function reveal1
assert(_valid_reveal1);
