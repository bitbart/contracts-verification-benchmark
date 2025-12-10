/*
- Deploy a Safe via SafeProxy with ExtensibleFallbackHandler set as the fallback handler.
- Set a non-zero method handler for a selector using setSafeMethod through a Safe transaction.
- Observe that ExtensibleFallbackHandler.safeMethods(safe, selector) is non-zero afterwards, and calling the selector on the Safe succeeds via the configured handler, proving that setSafeMethod did not remove the handler.

Concrete trace:
1) Create Safe proxy and call setup with one owner and fallbackHandler = ExtensibleFallbackHandler.
2) Prepare a Safe transaction to call setSafeMethod(selector, MarshalLib.encode(false, handlerAddr)) to the Safe itself (so onlySelf passes).
3) Owner pre-approves the txHash via approveHash.
4) Execute execTransaction with a v=1 “approved hash” pseudo-signature.
5) Verify safeMethods[safe][selector] != 0 and a subsequent call to safe.selector() returns from the handler.

FOUNDRY:
*/

pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../contracts/Safe.sol";
import "../contracts/proxies/SafeProxy.sol";
import "../contracts/handler/ExtensibleFallbackHandler.sol";
import "../contracts/handler/extensible/ExtensibleBase.sol";
import "../contracts/handler/extensible/MarshalLib.sol";
import "../contracts/libraries/Enum.sol";
import "../contracts/interfaces/ISafe.sol";

contract DummyMethod is IFallbackMethod {
    function handle(ISafe, address, uint256, bytes calldata) external pure override returns (bytes memory result) {
        return bytes("ok");
    }
}

contract SetSafeMethodPropertyTest is Test {
    address private owner = address(0xBEEF);
    Safe private safeImpl;
    SafeProxy private proxy;
    ISafe private safe;
    ExtensibleFallbackHandler private efh;
    DummyMethod private method;

    function setUp() public {
        vm.deal(owner, 100 ether);
        efh = new ExtensibleFallbackHandler();
        method = new DummyMethod();

        // Deploy Safe singleton and proxy
        safeImpl = new Safe();
        proxy = new SafeProxy(address(safeImpl));
        safe = ISafe(payable(address(proxy)));

        // Setup Safe via proxy with the EFH as fallback handler
        address[] memory owners = new address[](1);
        owners[0] = owner;
        safe.setup(
            owners,
            1,
            address(0),
            "",
            address(efh),
            address(0),
            0,
            payable(address(0))
        );
    }

    function _encodeMethod(bool isStatic, address handler) internal pure returns (bytes32 data) {
        uint256 val = uint256(uint160(handler));
        if (!isStatic) {
            val |= (1 << 248); // match MarshalLib.encode(false, handler)
        }
        data = bytes32(val);
    }

    function _buildApprovedHashSignature(address _owner) internal pure returns (bytes memory sig) {
        // v = 1, r = owner address, s = 0; satisfies the "approved hash" branch in checkNSignatures
        bytes32 r = bytes32(uint256(uint160(_owner)));
        bytes32 s = bytes32(0);
        uint8 v = 1;
        sig = abi.encodePacked(r, s, bytes1(v));
    }

    function test_setSafeMethodDoesNotRemoveHandler() public {
        // Prepare call to set a handler for a selector
        bytes4 selector = bytes4(keccak256("foo()"));
        bytes32 newMethod = _encodeMethod(false, address(method)); // non-zero handler => should NOT remove

        bytes memory data = abi.encodeWithSelector(
            IFallbackHandler.setSafeMethod.selector,
            selector,
            newMethod
        );

        // Build Safe execTransaction to call itself (so onlySelf passes in handler)
        address to = address(safe);
        uint256 value = 0;
        Enum.Operation operation = Enum.Operation.Call;
        uint256 safeTxGas = 0;
        uint256 baseGas = 0;
        uint256 gasPrice = 0;
        address gasToken = address(0);
        address payable refundReceiver = payable(address(0));

        // Precompute txHash and approve it from the owner (v=1 approved-hash path)
        uint256 nonce = safe.nonce();
        bytes32 txHash = safe.getTransactionHash(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            nonce
        );

        vm.prank(owner);
        safe.approveHash(txHash);

        bytes memory signatures = _buildApprovedHashSignature(owner);

        // Execute the transaction
        bool success = safe.execTransaction(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            signatures
        );
        assertTrue(success, "execTransaction failed");

        // Verify handler was SET (not removed)
        bytes32 stored = efh.safeMethods(ISafe(payable(address(safe))), selector);
        assertTrue(stored != bytes32(0), "setSafeMethod removed the handler unexpectedly");

        // Additionally verify that calling the selector routes to our method handler
        (bool ok, bytes memory ret) = address(safe).call(abi.encodeWithSignature("foo()"));
        assertTrue(ok, "call to foo() failed via fallback");
        assertEq(string(ret), "ok", "handler did not execute");
    }
}

/*
How to run:
- Place this file at: test/SetSafeMethodPropertyTest.t.sol
- From the repository root, run:
  forge test -vv

This test demonstrates that setSafeMethod sets a non-zero handler (does not remove it), contradicting the property “setSafeMethod removes the handler.”
*/