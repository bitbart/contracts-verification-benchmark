# Crowdfund

## Specification
The Crowdfund contract implements a crowdfunding campaign. 

The constructor specifies the `owner` of the campaign, the last block height where it is possible to receive donations (`end_donate`), and the `goal` in ETH that must be reached for the campaign to be successful. 

The contract implements the following methods:
- `donate`, which allows anyone to deposit any amount of ETH in the contract. Donations are only possible before the donation period has ended;
- `withdraw`, which allows the `owner` to redeem all the funds deposited in the contract. This is only possible if the campaign `goal` has been reached;   
- `reclaim`, which all allows donors to reclaim their donations after the donation period has ended. This is only possible if the campaign `goal` has not been reached.

## Properties
- **bal-decr-onlyif-wd-reclaim**: after the donation phase, if the contract balance decreases then either a successful `withdraw` or `reclaim` have been performed.
- **donate-bal-inc**: a non-reverting call to `donate` does not decrease the balance of the contract.
- **donate-not-dec-donation**: if the donation period has not ended and there is a non-reverting `donate` transaction by user A, then `donation[A]` is not decreased.
- **donate-not-revert**: a transaction `donate` is not reverted if the donation phase has not ended.
- **donate-not-revert-overflow**: a transaction `donate` is not reverted if the donation phase has not ended and sum between the old and the current donation does not overflow.
- **donation-dec-onlyif-reclaim**: if `donation[A]` decreases after a transaction (of the Crowdfund contract), then that transaction must be a `reclaim` where A is the sender.
- **donation-inc-onlyif-donate**: if `donation[A]` is increased after a transaction (of the Crowdfund contract), then that transaction must be a `donate` where A is the sender.
- **exists-unique-donation-change**: after a non-reverting `donate` transaction to the Crowdfund contract, the donation of exactly one user has changed.
- **goal-not-change**: The value of `goal` does not change after its value is initialized in the constructor.
- **msgvalue-not-negative**: The `msg.value` for a call to `donate` should not be negative.
- **no-donate-after-deadline**: calls to `donate` will revert if the donation phase has ended.
- **no-receive-after-deadline**: the contract balance does not increase after the end of the donation phase.
- **no-wd-if-no-goal**: calls to `withdraw` will revert if the contract balance is less than the `goal`.
- **owner-not-change**: The address `owner` does not change after its value is initialized in the constructor.
- **owner-only-recv**: only the owner can receive ETH from the contract.
- **reclaim-even-if-msgvalue**: For a call to `reclaim` by `msg.sender` A, the call executes as expected even if `msg.value` is non-zero.
- **reclaim-not-revert**: a transaction `reclaim` is not reverted if the goal amount is not reached and the deposit phase has ended, and the sender has donated funds that they have not reclaimed yet.
- **reclaim-own-funds**: after a non-reverting `reclaim` by `msg.sender` A, the ETH balance of A is increased by an amount equal to `donation[A]` before `reclaim` was called.
- **wd-empties-balance**: after a non-reverting `withdraw`, the ETH balance of the Crowdfund contract is equal to zero.
- **wd-not-revert**: a transaction `withdraw` is not reverted if the contract balance is greater than or equal to the goal and the donation phase has ended.
- **wd-not-revert-EOA**: a transaction `withdraw` is not reverted if the contract balance is greater than or equal to the goal, the donation phase has ended, and the `receiver` is an EOA.
- **wd-transfer-to-owner**: after a non-reverting `withdraw`, the ETH balance of owner is increased by an amount equal to the balance (of Crowdfund) before `withdraw` was called.

## Versions
- **v1**: conforming to specification.
- **v2**: end_donate = type(uint256).max i.e donation period never ends and no `require (block.number > end_donate)` check in `withdraw`.
- **v3**: `owner` not immutable & `setOwner` allows any user to set itself as owner.
- **v4**: `donate` transfers part of `msg.value` to the owner and `reclaim` witholds 1 wei from the donor.
- **v5**: uint goal not immutable and no `require (address(this).balance >= goal)` check in `withdraw`.
- **v6**: `withdraw` allows any user to withdraw.
- **v7**: `require(succ)` replaced with `require(!succ)` in `withdraw` and `reclaim`, i.e funds frozen within contract.
- **v8**: no `require (block.number > end_donate)` check, i.e any user can reclaim before `end_donate`.
- **v9**: no `donation[msg.sender] += msg.value` check & `donate` returns (msg.value - 1) while claiming "donation reverted".
- **v10**: `donate`, `withdraw` and `reclaim` are non-reentrant. `owner_.code.length == 0`, `goal_ > 0`, `end_donate_ > block.number` check in `constructor`, and `require(address(this).balance == 0)` check in `withdraw`. 

## Verification data

- [Ground truth](ground-truth.csv)
- [Solcmc/z3](solcmc-z3.csv)
- [Solcmc/Eldarica](solcmc-eld.csv)
- [Certora](certora.csv)

## Experiments
