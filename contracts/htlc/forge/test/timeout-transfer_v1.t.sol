// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "../src/Htlc_v1.sol";

contract Verifier {
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
        Verifier ver_contract = new Verifier(fwd_addr);

        // Owner deploys the HTLC contract
        vm.startPrank(owner);
        htlc = new Htlc(payable(ver_contract));

        // Owner commits a hash
        string memory s;
        bytes32 h = htlc.hashing(s);
        htlc.commit{value: FEE}(h);
        vm.stopPrank();

        uint256 verifier_bal_before = address(ver_contract).balance;
        uint256 forward_bal_before = address(fwd_addr).balance;

        // After the specified waitTime, it is possible to trigger the timeout
        vm.roll(htlc.start() + htlc.waitTime() + 1);
        htlc.timeout();

        uint256 verifier_bal_after = address(ver_contract).balance;
        uint256 forward_bal_after = address(fwd_addr).balance;

        assert(forward_bal_after > forward_bal_before);
        assert(verifier_bal_before == verifier_bal_after);
    }
}
