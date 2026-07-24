// The contract's balance should only increase if the `commit()` function is called

/// @custom:ghost
uint256 _preBal;
uint256 _postBal;

/// @custom:preghost function commit
_preBal = address(this).balance - msg.value;

/// @custom:preghost function reveal
_preBal = address(this).balance;

/// @custom:preghost function timeout
_preBal = address(this).balance;

/// @custom:postghost function commit
_postBal = address(this).balance;

/// @custom:postghost function reveal
_postBal = address(this).balance;

/// @custom:postghost function timeout
_postBal = address(this).balance;

/// @custom:invariant
function invariant() internal view {
    if (_postBal > _preBal) {
        assert(msg.sig == this.commit.selector);
    }
}