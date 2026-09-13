// SolCMC has no existential satisfy semantics, it is then necessary to
// hard-code the intended witness (`redeem1_noreveal0`) 

/// @custom:ghost
uint256 _pot_before;

/// @custom:preghost function redeem1_noreveal0
_pot_before = address(this).balance;
require(status == Status.Reveal0);
require(_pot_before > 0);

/// @custom:postghost function redeem1_noreveal0
assert(address(this).balance == 0);
