const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

describe("Vault property violation: amount can exceed balance in REQ", function () {
  async function deployFixture() {
    const [owner, recovery, receiver] = await ethers.getSigners();
    const Vault = await ethers.deployContract("Vault", [await recovery.getAddress(), 1], { value: 0 });
    await Vault.waitForDeployment();
    return { Vault, owner, recovery, receiver };
  }

  it("violates: in REQ, amount can be greater than contract balance", async function () {
    const { Vault, owner, receiver } = await loadFixture(deployFixture);

    // Owner requests withdrawal of 1 ether while contract balance is 0
    await Vault.connect(owner).withdraw(await receiver.getAddress(), ethers.parseEther("1"));

    const vaultAddr = await Vault.getAddress();
    const balance = await ethers.provider.getBalance(vaultAddr);

    // Read storage directly: amount at slot 5, state at slot 6
    const amountHex = await ethers.provider.getStorage(vaultAddr, 5);
    const stateHex = await ethers.provider.getStorage(vaultAddr, 6);

    const amount = BigInt(amountHex);
    const state = BigInt(stateHex);

    // States enum: IDLE=0, REQ=1
    expect(state).to.equal(1n); // REQ
    expect(amount > balance).to.equal(true); // amount exceeds contract balance
  });
});
