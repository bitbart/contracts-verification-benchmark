/// @custom:preghost function compute_winner
address payable expectedWinner = ((bytes(s0).length + bytes(s1).length) % 2 == 0) ? p0 : p1;

/// @custom:postghost function compute_winner
assert(w == expectedWinner);