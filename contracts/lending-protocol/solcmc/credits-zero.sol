  // --model-checker-ext-calls trusted

function invariant(address t) public view {
    require(isValidToken(t));
    assert(
            sum_credits[t] != 0 ||
            (sum_debits[t] == 0 && reserves[t] == 0)
    );
}