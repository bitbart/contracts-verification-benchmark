// Calling `commit` after a successful call to `commit` should revert

/// @custom:ghost
bool _succesful_commit;
// State when new commit call
bool _already_commit;

/// @custom:preghost function commit
_already_commit = _succesful_commit;

/// @custom:postghost function commit
assert(!_already_commit);
_succesful_commit = true;

// COME CHIAMIAMO QUESTE VARIABILI