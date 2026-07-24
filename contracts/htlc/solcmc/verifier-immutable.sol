// No function call should change the address of the verifier

/// @custom:ghost
address _pre_verifier;
bool _initialized;

/// @custom:invariant
function invariant() internal {
    if (_initialized) {
        assert(verifier == _pre_verifier);
    }
    _pre_verifier = verifier;
    _initialized = true;
}