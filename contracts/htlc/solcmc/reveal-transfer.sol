// If `reveal()` is successful, `owner`'s balance must increase by at least the balance of the contract

/// @custom:preghost function reveal
require(address(this) != owner);
uint256 _pre_contract_bal = address(this).balance;
uint256 _pre_owner_bal = owner.balance;

/// @custom:postghost function reveal
assert(owner.balance >= _pre_owner_bal + _pre_contract_bal);