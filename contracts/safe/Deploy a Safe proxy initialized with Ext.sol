/*Deploy a Safe proxy initialized with ExtensibleFallbackHandler as its fallback handler. Have the Safe’s owner execute a transaction to the handler calling setSafeMethod(selector=0xdeadbeef, newMethod=bytes32(uint160(address(safe)))). The call passes onlySelf, and since the decoded handler address is non-zero (the Safe’s address), safeMethods[safe][selector] becomes non-zero, i.e., the handler is not removed.
FOUNDRY:
- Save as test/SetSafeMethodDoesNotRemoveHandler.t.sol
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import "forge-std/Test.sol";

import {ISafe} from "../contracts/interfaces/ISafe.sol";
import {Enum} from "../contracts/libraries/Enum.sol";
import {Safe} from "../contracts/Safe.sol";
import {SafeProxy} from "../contracts/proxies/SafeProxy.sol";
import {SafeProxyFactory} from "../contracts/proxies/SafeProxyFactory.sol";
import {ExtensibleFallbackHandler} from "../contracts/handler/ExtensibleFallbackHandler.sol";

contract SetSafeMethodDoesNotRemoveHandlerTest is Test {
    Safe internal safeSingleton;
    ExtensibleFallbackHandler internal handler;
    SafeProxyFactory internal factory;

    address internal owner;
    uint256 internal ownerPk;

    function setUp() public {
        ownerPk = 0xA11CE;
        owner = vm.addr(ownerPk);

        // Deploy singleton (logic) and factory/handler
        safeSingleton = new Safe();
        handler = new ExtensibleFallbackHandler();
        factory = new SafeProxyFactory();

        // Initialize a Safe proxy with our owner and the extensible fallback handler
        address[] memory owners = new address[](1);
        owners[0] = owner;

        bytes memory initializer = abi.encodeWithSelector(
            Safe.setup.selector,
            owners,
            uint256(1),               // threshold
            address(0),               // to
            bytes(""),                // data
            address(handler),         // fallbackHandler
            address(0),               // paymentToken
            uint256(0),               // payment
            payable(address(0))       // paymentReceiver
        );

        SafeProxy proxy = factory.createProxyWithNonce(address(safeSingleton), initializer, 0);
        // From here on, interact with the proxy via the Safe interface
        safe = ISafe(payable(address(proxy)));
    }

    ISafe internal safe; // proxy instance

    function test_setSafeMethodDoesNotRemoveHandler() public {
        // We will call handler.setSafeMethod(selector, newMethod) via the Safe.
        // onlySelf in the handler expects the last 20 bytes of calldata to equal the Safe address.
        // Since setSafeMethod has (bytes4 selector, bytes32 newMethod), the last 20 bytes are the tail of newMethod.
        // Make newMethod's lower 20 bytes = address(safe), which also makes the handler non-zero (so not removed).
        bytes4 selector = 0xdeadbeef;
        bytes32 newMethod = bytes32(uint256(uint160(address(safe)))); // lower 20 bytes = Safe address

        bytes memory callData = abi.encodeWithSelector(
            ExtensibleFallbackHandler.setSafeMethod.selector,
            selector,
            newMethod
        );

        // Craft a minimal signature using the Safe's "v == 1" approval path:
        // Set currentOwner to the tx executor by encoding owner address in r, s = 0, v = 1.
        bytes memory signatures = abi.encodePacked(
            bytes32(uint256(uint160(owner))), // r = owner address
            bytes32(uint256(0)),              // s = 0
            bytes1(uint8(1))                  // v = 1 (special approval path)
        );

        vm.prank(owner);
        bool success = safe.execTransaction(
            address(handler),
            0,
            callData,
            Enum.Operation.Call,
            0,                // safeTxGas
            0,                // baseGas
            0,                // gasPrice
            address(0),       // gasToken
            payable(address(0)),
            signatures
        );
        assertTrue(success, "execTransaction failed");

        // Verify the handler was NOT removed: mapping value must be non-zero
        bytes32 stored = ExtensibleFallbackHandler(address(handler)).safeMethods(safe, selector);
        assertTrue(stored != bytes32(0), "setSafeMethod removed the handler unexpectedly");
    }
}

/*
```

How to run:
- Ensure Foundry is installed (forge).
- From the project root, run:
  - forge test -vv
```
*/