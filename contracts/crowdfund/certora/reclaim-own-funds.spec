
/// reclaim-own-funds:
/// after a non-reverting `reclaim`,
/// the balance of the `msg.sender` A is increased by `donation[A]`

rule reclaim_own_funds {
    env e;
    
    require(nativeBalances[currentContract] < currentContract.goal);
    require(e.block.number > currentContract.end_donate);
    require(currentContract.donation[e.msg.sender] > 0);
    require(e.msg.value == 0);

    // trivial check to rule out unrealistic scenarios
    require(e.msg.sender != currentContract);

    mathint bal_A_prev = nativeBalances[e.msg.sender];
    mathint donation_A = currentContract.donation[e.msg.sender];
    
    reclaim@withrevert(e);   

    mathint bal_A_next = nativeBalances[e.msg.sender];
 

    assert !lastReverted =>
    bal_A_next == bal_A_prev + donation_A;
}

