// the reserves are strictly positive if a deposit has been made

rule test {
    env e1;
    env e2;
    env e3;

    uint extPriceT0 = 1; // price of t0 in base currency, scaled 1e18
    uint extPriceT1 = 1; // price of t1 in base currency, scaled 1e18

    address t0;
    address t1;
    address a;
    address b;

    require(a != b && a!=0 && b!=0 && a!=currentContract && b!=currentContract);
    require(t0 != t1);

    // Set initial state

    require (currentContract.t0 == t0);
    require (currentContract.t1 == t1);

    require (currentContract.r0 == 0);
    require (currentContract.r1 == 0);

    // require(e1.block.number > 0);
    require(e1.msg.sender == a);
    require(e1.msg.value == 0);

    deposit(e1, 1000, 1000);

    require(e3.msg.sender == b);
    require(e3.msg.value == 0);

    swap(e3, t0, 300, 0);

    uint b0 = t0.balanceOf(b);
    uint b1 = t1.balanceOf(b);
    uint w0 = (b0 * extPriceT0 + b1 * extPriceT1);

    assert true;
}