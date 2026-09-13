// SolCMC has no existential satisfy semantics, it is then necessary to
// hard-code the intended witness (`redeem0_nojoin1`)

/// @custom:ghost
uint256 _pot_before;

/// @custom:preghost function redeem0_nojoin1
_pot_before = address(this).balance;
require(status == Status.Join1);
require(_pot_before > 0);

/// @custom:postghost function redeem0_nojoin1
assert(address(this).balance == 0);
