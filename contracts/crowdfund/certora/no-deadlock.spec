
/// no-deadlock:
/// at least one of the main functions (donate, withdraw, reclaim) must not revert
/// if the contract has a balance and the caller has made a donation.

rule no_deadlock {

    env eDonate;
    env eWithdraw;
    env eReclaim;
    calldataarg args;

    
    require(nativeBalances[currentContract] > 0);
    
    require(currentContract.donation[eReclaim.msg.sender] > 0);

    require(eWithdraw.msg.value == 0);
    require(eReclaim.msg.value == 0);

    donate@withrevert(eDonate);
    bool donateReverted = lastReverted;

    withdraw@withrevert(eWithdraw, args);
    bool withdrawReverted = lastReverted;

    reclaim@withrevert(eReclaim);
    bool reclaimReverted = lastReverted;


    assert(!donateReverted || !withdrawReverted || !reclaimReverted);
}
