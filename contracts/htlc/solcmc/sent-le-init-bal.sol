//The overall sent amount does not exceed the initial deposit.

/// @custom:ghost
uint256 _sent;
uint256 _deposited;

/// @custom:postghost function commit
_deposited = address(this).balance;

/// @custom:postghost function reveal
_sent += _to_send;

/// @custom:postghost function timeout
_sent += _to_send;

/// @custom:invariant
function invariant() internal view {
   assert(_sent <= _deposited);
}