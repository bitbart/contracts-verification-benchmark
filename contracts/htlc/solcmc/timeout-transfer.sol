// When `timeout` is successfully called, then all the balance should be transferred to the verifier
/// @custom:ghost
uint256 _pre_verifier_bal;

/// @custom:preghost function timeout
_pre_verifier_bal = verifier.balance;

/// @custom:postghost function timeout
if (verifier != owner) {
    assert(verifier.balance >= _pre_verifier_bal);
}