// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "versions/Htlc_v1.sol";

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
    Htlc h;
    uint fee;

    function setUp() public {
        fee = 1 ether;
    }

    function test_timeout_transfer(address owner) public {
        // Initialization
        address payable fwd_addr = payable(address(123));
        Verifier ver_contract = new Verifier(fwd_addr);

        // Owner deploys the HTLC contract
        vm.deal(owner, fee);
        vm.startPrank(owner);
        h = new Htlc(payable(ver_contract));

        // Owner commits a hash
        string memory s;
        bytes32 hash = h.hashing(s);
        h.commit{value: fee}(hash);
        vm.stopPrank();

        uint256 verifier_bal_before = address(ver_contract).balance;
        uint256 forward_bal_before = address(fwd_addr).balance;

        // After the specified waitTime, it is possible to trigger the timeout
        vm.roll(h.start() + h.waitTime() + 1);
        h.timeout();

        uint256 verifier_bal_after = address(ver_contract).balance;
        uint256 forward_bal_after = address(fwd_addr).balance;

        assert(forward_bal_after > forward_bal_before);
        assert(verifier_bal_before == verifier_bal_after);
    }
}
