// SPDX-License-Identifier: GPL-3.0-only

// If a `reveal1(s)` transaction does not revert, then `s` is a preimage of the committed hash

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery --verify Lottery:certora/wrong-preimage-reverts-p1.spec --optimistic_hashing
rule wrong_preimage_reverts_p1 {
    env e;
    bytes32 committed_hash;
    bytes32 secret_hash;
    string secret;

    require e.msg.sender == currentContract.player1;
    require currentContract.status == Lottery.Status.Reveal1;
    committed_hash = currentContract.hash1;

    secret_hash = hashing(e, secret);

    require secret_hash != committed_hash;

    reveal1@withrevert(e, secret);

    assert lastReverted;
}
