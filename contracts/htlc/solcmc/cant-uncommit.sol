// Once `isCommitted` is set to true, no call to function can unset it

/// @custom:ghost
bool _wasCommitted;

// THIS GHOST IS UPDATED FROM THE INVARIANT, IS IT OCRRECET???
// SHOULD WE ADD A POSTGHOST FOR COMMIT??

/// @custom:invariant
function invariant() public payable {
    if (_wasCommitted) {
        assert(isCommitted);
    }
    _wasCommitted = isCommitted;
}


// CLAUDE QUESTION

/* This is the version of the implementation that can formally verify the following property using solCMC: "// Once `isCommitted` is set to true, no call to function can unset it"

As you can see, past me added some comment, answer to their questions */