// SPDX-License-Identifier: GPL-3.0-only

// Assuming `player0` and `player1` are EOAs: in any state where the winner is not yet determined, for every
// transaction whose sender is neither `player0` nor `player1`; if such transaction changes the contract storage,
// then the same transaction (except for `msg.sender`), made by any EOA, in the same state, must produce the same
// state modifications

/// @custom:run certoraRun versions/Lottery_v1.sol:Lottery versions/lib/EOA0.sol versions/lib/EOA1.sol --verify Lottery:certora/owner-impartiality-eoa.spec --optimistic_hashing --link Lottery:player0=EOA0 --link Lottery:player1=EOA1
rule owner_impartiality_eoa(method f)
filtered {
    f -> !f.isView &&
         !f.isPure &&
         f.contract == currentContract
} {
    address addr;
    require addr != currentContract;
    require addr != 0;
    
    address p0_pre  = currentContract.player0;
    require p0_pre != currentContract;
    require p0_pre != addr;
    require p0_pre != 0;

    address p1_pre  = currentContract.player1;
    require p1_pre != currentContract;
    require p1_pre != addr;
    require p1_pre != 0;

    require p0_pre != p1_pre;

    env e1;
    require e1.msg.sender == addr;

    env e2;
    require e2.msg.sender != p0_pre;
    require e2.msg.sender != p1_pre;
    require e2.msg.sender != addr;
    require e2.msg.sender != currentContract;
    require e2.msg.sender != 0;

    // the only difference between the two envs is the caller
    require e2.block.number == e1.block.number;
    require e2.block.timestamp == e1.block.timestamp;
    require e2.msg.value == e1.msg.value;

    calldataarg args;
    
    require currentContract.winner == 0;

    // Save storage status, so that same call can be repeated
    storage initStorage = lastStorage;

    // contract state before
    uint status_pre = _status(e1);
    mathint bet_pre = currentContract.bet_amount;
    bytes32 h0_pre  = currentContract.hash0;
    bytes32 h1_pre  = currentContract.hash1;
    uint ej_pre     = currentContract.end_join;
    uint er_pre     = currentContract.end_reveal0;
    uint rd_pre     = currentContract.end_reveal1;
    address w_pre   = currentContract.winner;
    mathint bal_pre = nativeBalances[currentContract];
    string s0_pre;    require s0_pre == secret0(e1);
    string s1_pre;    require s1_pre == secret1(e1);

    // addr attempts the call from the initial snapshot
    f(e1, args) at initStorage;

    bool e1_changed_state =
        status_pre != _status(e1)                     ||
        p0_pre     != currentContract.player0         || 
        p1_pre     != currentContract.player1         ||
        bet_pre    != currentContract.bet_amount      ||
        h0_pre     != currentContract.hash0           ||
        h1_pre     != currentContract.hash1           ||
        ej_pre     != currentContract.end_join        ||
        er_pre     != currentContract.end_reveal0     ||
        rd_pre     != currentContract.end_reveal1     ||
        w_pre      != currentContract.winner          ||
        bal_pre    != nativeBalances[currentContract] ||
        s0_pre     != secret0(e1)                     ||
        s1_pre     != secret1(e1);

    // replay the exact same call, from the same snapshot, as other user
    f@withrevert(e2, args) at initStorage;

    bool e2_could_run_fun = !lastReverted;

    bool e2_changed_state =
        status_pre != _status(e2)                     ||
        p0_pre     != currentContract.player0         || 
        p1_pre     != currentContract.player1         ||
        bet_pre    != currentContract.bet_amount      ||
        h0_pre     != currentContract.hash0           ||
        h1_pre     != currentContract.hash1           ||
        ej_pre     != currentContract.end_join        ||
        er_pre     != currentContract.end_reveal0     ||
        rd_pre     != currentContract.end_reveal1     ||
        w_pre      != currentContract.winner          ||
        bal_pre    != nativeBalances[currentContract] ||
        s0_pre     != secret0(e2)                     ||
        s1_pre     != secret1(e2);

    assert e1_changed_state => (e2_could_run_fun && e2_changed_state);
}