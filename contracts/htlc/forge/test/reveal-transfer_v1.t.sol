// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "versions/Htlc_v1.sol";

contract Owner {
    address payable addr;

    constructor(address payable _a) {
        addr = _a;
    }

    receive() external payable {
        (bool success,) = payable(addr).call{value: msg.value}(""); // M immediately forwards the received amount to A
    }
}

contract HtlcTest is Test {
    Htlc htlc;

    uint256 constant FEE = 1 ether;

    address owner = address(0x1);
    address verifier = address(0x2);
    
    string secret = "secret";
    
    function setUp() public {
        vm.deal(owner, FEE);
    }

    function test_timeout_transfer() public {
        // Initialization
        address payable fwd_addr = payable(address(123));
        Owner own_contract = new Owner(fwd_addr);

        // Owner deploys the HTLC contract
        vm.startPrank(owner);
        htlc = new Htlc(payable(verifier));

        // Owner commits a hash
        bytes32 h = htlc.hashing(secret);
        htlc.commit{value: FEE}(h);

        uint256 owner_bal_before = address(own_contract).balance;
        uint256 forward_bal_before = address(fwd_addr).balance;

        htlc.reveal(secret);
        vm.stopPrank();

        uint256 owner_bal_after = address(own_contract).balance;
        uint256 forward_bal_after = address(fwd_addr).balance;

        assert(forward_bal_after > forward_bal_before);
        assert(owner_bal_before == owner_bal_after);
    }
}
