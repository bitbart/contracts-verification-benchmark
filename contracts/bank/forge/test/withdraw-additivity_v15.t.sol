// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank_v15.sol";


contract BankTest is Test {

    Bank public b;

    function setUp() public {
    }

    // withdraw-additivity:
    // if the same sender can perform two non-reverting consecutive
    // (i.e., not interleaved with other transactions) withdraw of n1 and n2 wei, respectively,
    // then the same sender can always obtain an equivalent effect
    // (on the state of the Bank contract and on its own account) through a single withdraw of n1+n2 wei.
    // Here equivalence neglects transaction fees.

    // PoC produced by GPT-5:
    // Let a user U have credits[U] = 100.
    // Assume a block B where, before any withdraws, currentBlockNo != B or opsInCurrentBlock has been reset to 0 for block B.
    // Two consecutive withdraws in block B:
    //  1) U calls withdraw(30): passes checks, credits[U] becomes 70, opsInCurrentBlock becomes 1, currentBlockNo = B.
    //  2) U calls withdraw(20): passes checks, credits[U] becomes 50, opsInCurrentBlock becomes 2, currentBlockNo = B.
    // Single withdraw attempt from the same initial state:
    // U calls withdraw(50) in block B: passes checks, credits[U] becomes 50, opsInCurrentBlock becomes 1, currentBlockNo = B.
    // Final states differ: after two withdraws opsInCurrentBlock = 2, after one withdraw opsInCurrentBlock = 1.
    // Therefore, the single withdraw cannot achieve an equivalent effect on the contract state.



    function test_deposit_not_revert() public {
        // Initialization
        address owner = address(123);
        address U = address(456);
        
        // owner deploys the Bank contract
        vm.prank(owner);
        b = new Bank();

        // Funding U
        vm.deal(address(U), 1 ether);

        // Ensuring U has credits[U] = 100
        vm.prank(address(U));
        b.deposit{value: 100}();

        // Start with a fresh block
        uint256 next_block = block.number + 1;
        vm.roll(next_block);

        // Scenario 1: U calls withdraw(30) & withdraw(20) consecutively
        uint256 snapshot = vm.snapshot();
        vm.startPrank(address(U));

        (bool success1,) = address(b).call(abi.encodeWithSignature("withdraw(uint256)",30));
        assert(success1);                                       // Ensuring withdraw() does not revert
        
        (bool success2,) = address(b).call(abi.encodeWithSignature("withdraw(uint256)",20));
        assert(success2);                                       // Ensuring withdraw() does not revert
        vm.stopPrank();

        uint ops_1 = b.opsInCurrentBlock();

        
        // Scenario 2: U calls withdraw(50)
        vm.revertTo(snapshot);
        vm.prank(address(U));
        (bool success3,) = address(b).call(abi.encodeWithSignature("withdraw(uint256)",50));
        assert(success3);                                       // Ensuring withdraw() does not revert

        uint ops_2 = b.opsInCurrentBlock();


        // The same sender performs two non-reverting consecutive withdraws but
        // CANNOT obtain an equivalent effect (on the state of the Bank contract)
        // through a single withdraw
        assert(ops_1 != ops_2);

    }

}