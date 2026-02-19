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
- **donate-not-revert**: a transaction `donate` is not reverted if the donation phase has not ended.
- **donate-not-revert-overflow**: a transaction `donate` is not reverted if the donation phase has not ended and sum between the old and the current donation does not overflow.
- **no-donate-after-deadline**: calls to `donate` will revert if the donation phase has ended.
- **no-receive-after-deadline**: the contract balance does not increase after the end of the donation phase.
- **no-wd-if-no-goal**: calls to `withdraw` will revert if the contract balance is less than the `goal`.
- **owner-only-recv**: only the owner can receive ETH from the contract.
- **reclaim-not-revert**: a transaction `reclaim` is not reverted if the goal amount is not reached and the deposit phase has ended, and the sender has donated funds that they have not reclaimed yet.
- **wd-not-revert**: a transaction `withdraw` is not reverted if the contract balance is greater than or equal to the goal and the donation phase has ended.
- **wd-not-revert-EOA**: a transaction `withdraw` is not reverted if the contract balance is greater than or equal to the goal, the donation phase has ended, and the `receiver` is an EOA.
- **donation-inc-onlyif-donate**:  if `donation[A]` is increased after a transaction (of the Crowdfund contract), then that transaction must be a `donate` where A is the sender.
- **donate-bal-inc**: a non-reverting call to `donate` does not decrease the balance of the contract.
- **wd-full-balance**: after a non-reverting `withdraw`, the whole balance of the contract is sent to `owner`.
- **exists-unique-donation-change**: after a non-reverting `donate` transaction to the Crowdfund contract, the donation of exactly one user has changed.
- **donate-not-dec-donation**:  after a non-reverting `donate` transaction by user A, `donation[A]` is not decreased.
- **donation-dec-onlyif-reclaim**: if `donation[A]` decreases after a transaction (of the Crowdfund contract), then that transaction must be a `reclaim` where A is the sender.
- **reclaim-own-funds**: after a non-reverting `reclaim`, the balance of the `msg.sender` A is increased by `donation[A]`


## Versions
- **v1**: conforming to specification.
- **v2**: donation period never ends, i.e end_donate = type(uint256).max.
- **v3**: no `require (block.number > end_donate)` check.
- **v4**: `donate` transfers part of `msg.value` to the owner.
- **v5**: uint goal not immutable.
- **v6**: no `require (address(this).balance >= goal)` check.
- **v7**: `require(succ)` replaced with `require(!succ)`, i.e funds frozen within contract.
- **v8**: `reclaim` witholds 1 wei from the donor.
- **v9**: no `donation[msg.sender] += msg.value` and `donate()` returns (msg.value - 1) while claiming that donation failed.
- **v10**: `owner` not immutable and setOwner allows any user to set itself as owner.
- **v11**: `withdraw` allows any user to withdraw.
- **v12**: no `require (block.number > end_donate)` check, i.e any user can reclaim before `end_donate`.
- **v13**: `withdraw` is non-reentrant.
- **v14**: `donate` and `withdraw` are non-reentrant.
- **v15**: `donate`, `withdraw` and `reclaim` are non-reentrant. `owner_.code.length == 0` check. `goal_ > 0` check. `end_donate_ > block.number` check.


## Ground truth
|        | bal-decr-onlyif-wd-reclaim | donate-not-revert          | donate-not-revert-overflow | no-donate-after-deadline   | no-receive-after-deadline  | no-wd-if-no-goal           | owner-only-recv            | reclaim-not-revert         | wd-not-revert              | wd-not-revert-EOA          |
|--------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| **v1** | 1                          | 0[^1]                      | 1                          | 1                          | 0[^2]                      | 1                          | 1                          | 0[^3]                      | 0[^4]                      | 1                          |
 
[^1]: This property should be false, since the increment of the `donors` map could overflow.
[^2]: This property should always be false, since a contract can receive ETH when its address is specified in a coinbase transaction or in a `selfdestruct`.
[^3]: All funds may have been reclaimed already.
[^4]: Receiver of the funds may revert the transaction.

## Experiments
### SolCMC
#### Z3
|        | bal-decr-onlyif-wd-reclaim | donate-not-revert          | donate-not-revert-overflow | no-donate-after-deadline   | no-receive-after-deadline  | no-wd-if-no-goal           | owner-only-recv            | reclaim-not-revert         | wd-not-revert              | wd-not-revert-EOA          |
|--------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| **v1** | TP!                        | ND                         | ND                         | TP!                        | TN!                        | TP!                        | ND                         | ND                         | ND                         | ND                         |
 

#### Eldarica
|        | bal-decr-onlyif-wd-reclaim | donate-not-revert          | donate-not-revert-overflow | no-donate-after-deadline   | no-receive-after-deadline  | no-wd-if-no-goal           | owner-only-recv            | reclaim-not-revert         | wd-not-revert              | wd-not-revert-EOA          |
|--------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| **v1** | TP!                        | ND                         | ND                         | TP!                        | TN!                        | TP!                        | ND                         | ND                         | ND                         | ND                         |
 


### Certora
|        | bal-decr-onlyif-wd-reclaim | donate-not-revert          | donate-not-revert-overflow | no-donate-after-deadline   | no-receive-after-deadline  | no-wd-if-no-goal           | owner-only-recv            | reclaim-not-revert         | wd-not-revert              | wd-not-revert-EOA          |
|--------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|----------------------------|
| **v1** | TP!                        | TN                         | TP!                        | TP!                        | ND                         | TP!                        | TP!                        | TN                         | TN                         | FN                         |
 

