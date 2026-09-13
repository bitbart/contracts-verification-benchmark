/// @custom:preghost function join1
bool _valid_join1 = msg.value == bet_amount;

/// @custom:postghost function join1
assert(_valid_join1);
