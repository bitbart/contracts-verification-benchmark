// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >= 0.8.2;
import "./lib/ReentrancyGuard.sol";

/// @custom:version non-reentrant `callwrap`.
contract CallWrapper is ReentrancyGuard {
    uint data = 0;

    function callwrap(address called) public nonReentrant {
        called.call("");
    }
}
