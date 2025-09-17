import "helper/methods.spec";
using EthPayerHarness as harness;

rule release_release_revert_receive {
    env e1; 
    uint index;
    address addr = getPayee(index);

    require currentContract != addr;
    require e1.msg.sender != currentContract;
    mathint released = releasable(addr);
    mathint balanceBefore = getBalance();

    // require that addr is not a contract which returnts ETH when
    // its receive() function is triggered

    storage initial = lastStorage;
    mathint balHarnessBefore = nativeBalances[harness];

    harness.pay(e1,addr,releasable(addr));

    mathint balHarnessAfter = nativeBalances[harness];
    require balHarnessAfter == balHarnessBefore - released;


    release(e1, addr) at initial; // First release call

    mathint balanceAfter = getBalance();

    release@withrevert(e1,addr); // Second release call, should revert
    assert lastReverted;
}





