//release-balance-contract invariant

function invariant(uint index) public {
    require(index < payees.length, "Index out of bounds");
    address payable a = payable(payees[index]);

    uint amt = releasable(a);

    uint balBefore_ps = address(this).balance;

    release(a);

    uint balAfter_ps = address(this).balance;

    assert(balBefore_ps == balAfter_ps + amt);
}

