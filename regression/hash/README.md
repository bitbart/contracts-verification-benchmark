# Hash

## Specification
The contract has a function `hashing` that computes the keccak256 hash of a string, and a function that verifies that two strings are equal

the property hash-can-collide should pass because there may be two strings that have the same hash

## Properties
- **hash-can-collide**: It is possible that two different preimages have the same hash

## Ground truth

- [Ground truth](ground-truth.csv)
- [Solcmc/z3](solcmc-z3.csv)
- [Solcmc/Eldarica](solcmc-eld.csv)
- [Certora](certora.csv)

## Experiments
### SolCMC
#### Z3
|        | hash-can-collide |
|--------|------------------|
| **v1** | FN!              |
 

#### ELD
|        | hash-can-collide |
|--------|------------------|
| **v1** | ERR              |
 


### Certora
|        | hash-can-collide |
|--------|------------------|
| **v1** | FN               |
 

