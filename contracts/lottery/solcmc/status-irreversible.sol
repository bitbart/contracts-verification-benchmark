/// @custom:ghost
uint8 _pre_status;

/// @custom:preghost function join0
_pre_status = uint8(status);

/// @custom:postghost function join0
assert(uint8(status) > _pre_status);

/// @custom:preghost function join1
_pre_status = uint8(status);

/// @custom:postghost function join1
assert(uint8(status) > _pre_status);

/// @custom:preghost function redeem0_nojoin1
_pre_status = uint8(status);

/// @custom:postghost function redeem0_nojoin1
assert(uint8(status) > _pre_status);

/// @custom:preghost function reveal0
_pre_status = uint8(status);

/// @custom:postghost function reveal0
assert(uint8(status) > _pre_status);

/// @custom:preghost function redeem1_noreveal0
_pre_status = uint8(status);

/// @custom:postghost function redeem1_noreveal0
assert(uint8(status) > _pre_status);

/// @custom:preghost function reveal1
_pre_status = uint8(status);

/// @custom:postghost function reveal1
assert(uint8(status) > _pre_status);

/// @custom:preghost function redeem0_noreveal1
_pre_status = uint8(status);

/// @custom:postghost function redeem0_noreveal1
assert(uint8(status) > _pre_status);

/// @custom:preghost function win
_pre_status = uint8(status);

/// @custom:postghost function win
assert(uint8(status) > _pre_status);
