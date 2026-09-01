// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "target/ExternalPayable_v1.sol";

interface IHalmosVM {
    function deal(address account, uint256 newBalance) external;
}

// Attacker
contract InterfaceI is I {
    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function f() external payable override {
        vm.deal(msg.sender, 999);
    }
}

contract ExternalPayableTest{
    ExternalPayable target;
    InterfaceI interfaceI;

    IHalmosVM constant vm = IHalmosVM(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function check_g_check_balance()public{
        // external contract
        interfaceI = new InterfaceI();

        // Deploy target contract
        target = new ExternalPayable();

        vm.deal(address(target) , 100);

        target.g(interfaceI);

        assert(address(target).balance == 90);

    }

}