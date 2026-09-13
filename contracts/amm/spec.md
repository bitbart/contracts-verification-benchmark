# AMM Specification

The Automated Market Maker (AMM) contract allows users to provide liquidity and swap tokens using a constant product formula ($x \times y = k$).

## Core Features
- **Deposit**: Users can add liquidity to the pool in exchange for LP (Liquidity Provider) tokens.
- **Redeem**: Users can burn their LP tokens to withdraw their proportional share of the underlying reserves.
- **Swap**: Users can trade one token for another.

## Requirements
- The contract maintains internal reserves (`r0` and `r1`).
- The AMM must not lock user funds without a valid economic reason.
- Operations should follow standard ERC20 token interactions.
