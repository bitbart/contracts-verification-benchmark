// If `timeout()` is successful, `verifier`'s balance must increase by at least the balance of the contract
/// @custom:ghost
uint256 _pre_verifier_bal;

/// @custom:preghost function timeout
_pre_verifier_bal = verifier.balance;

/// @custom:postghost function timeout
if (verifier != owner) {
    assert(verifier.balance >= _pre_verifier_bal);
}