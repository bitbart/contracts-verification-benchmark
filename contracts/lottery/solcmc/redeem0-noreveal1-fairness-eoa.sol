/// @custom:ghost
uint256 _p0_pre_bal;
uint256 _p1_pre_bal;
uint256 _contract_pre_bal;
address payable _expected_winner;

/// @custom:preghost function redeem0_noreveal1
_p0_pre_bal = player0.balance;
_p1_pre_bal = player1.balance;
_contract_pre_bal = address(this).balance;
_expected_winner = compute_winner(player0, player1, secret0, secret1);
require(_expected_winner == player0);

/// @custom:postghost function redeem0_noreveal1
assert(player0.balance == _p0_pre_bal + _contract_pre_bal);
assert(player1.balance == _p1_pre_bal);
assert(address(this).balance == _contract_pre_bal);