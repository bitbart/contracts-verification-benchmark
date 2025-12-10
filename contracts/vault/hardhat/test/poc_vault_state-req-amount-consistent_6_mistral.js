const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

describe("Vault", function() {
  async function deployContract() {
    const [owner, recovery, receiver] = await ethers.getSigners();
    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.deploy(recovery.address, 1);
    return { vault, owner, recovery, receiver };
  }

  it("State is REQ with amount > contract balance", async function() {
    const { vault, owner, receiver } = await loadFixture(deployContract);
    await vault.connect(owner).withdraw(receiver.address, 1);

    // Read storage slots (assuming Solidity layout)
    const stateSlot = await ethers.provider.getStorage(await vault.getAddress(), 5); // state
    const amountSlot = await ethers.provider.getStorage(await vault.getAddress(), 4); // amount
    const requestTimeSlot = await ethers.provider.getStorage(await vault.getAddress(), 3); // request_time
    const receiverSlot = await ethers.provider.getStorage(await vault.getAddress(), 2); // receiver
    const waitTimeSlot = await ethers.provider.getStorage(await vault.getAddress(), 1); // wait_time
    const recoverySlot = await ethers.provider.getStorage(await vault.getAddress(), 0); // recovery

    const state = parseInt(stateSlot, 16);
    const amount = BigInt(amountSlot);
    const balance = await ethers.provider.getBalance(await vault.getAddress());

    expect(state).to.equal(1); // REQ
    expect(amount).to.equal(1n);
    expect(balance).to.equal(0n);
    expect(amount).to.be.greaterThan(balance);
  });
});

