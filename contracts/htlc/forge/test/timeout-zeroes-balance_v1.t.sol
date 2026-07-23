// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "versions/Htlc_v1.sol";

contract Verifier {
    address payable addr;

    constructor() {}

    setAddr(address _addr) public {
        addr = _addr
    } 
    receive() external payable {
        (bool success,) = payable(addr).call{value: msg.value}(""); // M immediately forwards the received amount to A
    }
}

contract HtlcTest is Test {
    Htlc htlc;

    uint256 constant FEE = 1 ether;

    address owner = address(0x1);
    
    string secret = "secret";
    
    uint256 start;
    uint256 waitTime;

    function setUp() public {
        vm.deal(owner, FEE);
    }

    function test_reveal_zeroes_balance() public {
        // Owner deploys the HTLC contract
        vm.startPrank(owner);
        address ver_contract = new Verifier();
        htlc = new Htlc(payable(ver_contract));
        ver_contract.setAddr(htlc);

        start = htlc.start();
        waitTime = htlc.waitTime();

        // Owner commits a hash
        bytes32 h = htlc.hashing(secret);
        htlc.commit{value: FEE}(h);

        uint256 verifier_bal_before = address(ver_contract).balance;
        uint256 contract_bal_before = address(htlc).balance;

        vm.roll(start + waitTime);

        htlc.timeout();
        vm.stopPrank();

        uint256 verifier_bal_after = address(ver_contract).balance;
        uint256 contract_bal_after = address(htlc).balance;

        assert(contract_bal_after >= contract_bal_before);
        assert(verifier_bal_before == verifier_bal_after);
    }
}
