/// @custom:ghost
uint256 _contract_balance_before;

/// @custom:preghost function win
_contract_balance_before = address(this).balance;
address payable expectedWinner = compute_winner(player0, player1, secret0, secret1);

/// @custom:postghost function win
assert(winner == expectedWinner);
assert(address(this).balance == 0);
assert(_contract_balance_before == 0 || winner == expectedWinner);
