// No succesful function call should change contract's owner

/// @custom:ghost
address _pre_owner;
bool _initialized;

/// @custom:invariant
function invariant() internal {
    if (_initialized) {
        assert(owner == _pre_owner);
    }
    _pre_owner = owner;
    _initialized = true;
}