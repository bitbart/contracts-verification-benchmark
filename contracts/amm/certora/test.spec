// the reserves are strictly positive if a deposit has been made

// import "erc20.spec";
methods {
  // force the proper execution of the transfer() and transferFrom() functions
  // avoids HAVOC values
  function _.balanceOf(address) external => DISPATCHER(true);  
  function _.transferFrom(address,address,uint256) external => DISPATCHER(true);
  function _.transfer(address,uint256) external => DISPATCHER(true);
}

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

    uint x;
    uint ymin;
    address tok_call;

    require(a != b && a!=0 && b!=0 && a!=currentContract && b!=currentContract);
    require(t0 != t1);

    // Set initial state

    require (currentContract.t0 == t0);
    require (currentContract.t1 == t1);

    require (currentContract.r0 == 0);
    require (currentContract.r1 == 0);

    // A:deposit(1000,1000)
    require(e1.msg.sender == a);
    require(e1.msg.value == 0);
    deposit(e1, 1000, 1000);

    // A:swap(t0,300,0)
    require(e2.msg.sender == a);
    require(e2.msg.value == 0);
    swap(e2, t0, 300, 0);

    mathint b0 = t0.balanceOf(e2,b);
    mathint b1 = t1.balanceOf(e2,b);
    mathint wb = (b0 * extPriceT0 + b1 * extPriceT1);

    // B:swap(t1,x,ymin)
    require(e3.msg.sender == b);
    require(e3.tx.origin == b);
    require(e3.msg.value == 0);

    // Option 1: swap and token instantiated, x and ymin free
    // swap(e3, t1, x, ymin);
    
    // Option 2: swap instantiated, token, x, and ymin free
    //swap(e3, tok_call, x, ymin);

    // Option 3: everything free
    calldataarg args;
    method f;
    f(e3, args);



    mathint b0_after = t0.balanceOf(e3,b);
    mathint b1_after = t1.balanceOf(e3,b);
    mathint wb_after = (b0_after * extPriceT0 + b1_after * extPriceT1);

    assert(wb_after <= wb + 69);
    // 68 violated
    // 69 verified
}