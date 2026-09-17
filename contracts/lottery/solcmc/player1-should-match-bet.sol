// If a `join1` transaction doesn't revert then `msg.value` matched the bet
// made by `player0`

/// @custom:preghost function join1
bool _valid_join1 = msg.value == bet_amount;

/// @custom:postghost function join1
assert(_valid_join1);
