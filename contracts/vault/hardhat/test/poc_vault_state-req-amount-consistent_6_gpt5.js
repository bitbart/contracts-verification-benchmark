const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

describe("Vault property violation PoC", function () {
  async function deployVaultFixture() {
    const [owner, recovery, receiver] = await ethers.getSigners();
    const Vault = await ethers.deployContract("Vault", [await recovery.getAddress(), 1]);
    return { Vault, owner, recovery, receiver };
  }

  // Helper to read storage (compatible with ethers v5/v6)
  async function getStorage(provider, address, slot) {
    if (provider.getStorage) {
      return provider.getStorage(address, slot);
    }
    if (provider.getStorageAt) {
      return provider.getStorageAt(address, slot);
    }
    throw new Error("Provider does not support getStorage/getStorageAt");
  }

  it("can be in REQ with amount > balance", async function () {
    const { Vault, owner, recovery, receiver } = await loadFixture(deployVaultFixture);

    // Preconditions: contract balance is 0
    const vaultAddress = await Vault.getAddress();
    const initialBalance = await ethers.provider.getBalance(vaultAddress);
    expect(initialBalance).to.equal(0n);

    // Owner requests withdrawal of 1 wei to receiver
    await Vault.connect(owner).withdraw(await receiver.getAddress(), 1n);

    // Read private storage to confirm internal state:
    // Slots based on declaration order:
    // 5: amount (uint256)
    // 6: state (enum States; IDLE=0, REQ=1)
    const amountHex = await getStorage(ethers.provider, vaultAddress, 5);
    const stateHex = await getStorage(ethers.provider, vaultAddress, 6);

    const amount = BigInt(amountHex);
    const state = BigInt(stateHex);
    const balance = await ethers.provider.getBalance(vaultAddress);

    // Check that state == REQ and amount == 1 while balance == 0
    expect(state).to.equal(1n);      // States.REQ
    expect(amount).to.equal(1n);     // requested amount is 1 wei
    expect(balance).to.equal(0n);    // contract balance is 0 wei

    // Property violated: in REQ, amount should be <= balance, but here 1 > 0
    expect(amount > balance).to.be.true;
  });
});
