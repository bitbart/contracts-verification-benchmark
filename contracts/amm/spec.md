The Automated Market Maker (AMM) contract allows users to provide liquidity and swap tokens using a constant product formula ($x \times y = k$).

The contract has the following entry points:
- **deposit()**, which allows users to add liquidity to the pool in exchange for minted tokens;
- **redeem()**, which allows users to burn their minted tokens to withdraw their proportional share of the underlying reserves;
- **swap()**, which allows users to trade one token for another.

All operations follow standard ERC20 token interactions.
