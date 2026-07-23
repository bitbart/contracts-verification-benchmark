// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Htlc} from "versions/Htlc_v1.sol";

contract Owner {
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

    address verifier = address(0x2);
    
    string secret = "secret";
    
    function setUp() public {
        vm.deal(owner, FEE);
    }

    function test_reveal_zeroes_balance() public {
        Owner own_contract = new Owner();

        // Owner deploys the HTLC contract
        vm.startPrank(own_contract);
        htlc = new Htlc(payable(verifier));
        own_contract.setAddr(htlc);

        // Owner commits a hash
        bytes32 h = htlc.hashing(secret);
        htlc.commit{value: FEE}(h);

        uint256 owner_bal_before = address(own_contract).balance;
        uint256 contract_bal_before = address(htlc).balance;

        htlc.reveal(secret);
        vm.stopPrank();

        uint256 owner_bal_after = address(own_contract).balance;
        uint256 contract_bal_after = address(htlc).balance;

        assert(contract_bal_after >= contract_bal_before);
        assert(owner_bal_before == owner_bal_after);
    }
}
