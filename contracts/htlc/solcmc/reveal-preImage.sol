// If `reveal` does not revert, then the revealed string is a preimage of the committed hash
/// @custom:ghost
bytes32 _committed_hash;
bool _commit_success;

/// @custom:postghost function commit
_committed_hash = h;
_commit_success = true;

/// @custom:postghost function reveal
if (_commit_success) {
    assert(hashing(s) == _committed_hash);
}