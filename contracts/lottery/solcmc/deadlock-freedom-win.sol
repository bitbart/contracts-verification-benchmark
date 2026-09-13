// SolCMC has no existential satisfy semantics, it is then necessary to
// hard-code the intended witness (`win`)

/// @custom:ghost
uint256 _pot_before;

/// @custom:preghost function win
_pot_before = address(this).balance;
require(status == Status.Win);
require(_pot_before > 0);

/// @custom:postghost function win
assert(address(this).balance == 0);
