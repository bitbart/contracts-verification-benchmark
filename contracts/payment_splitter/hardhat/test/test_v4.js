const {
    loadFixture
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

const PANIC_OVERFLOW = 0x11;

describe("PaymentSplitter_v4", function () {

    //     fair-split-eq
    { 
        async function deployContract(){

            const [payee] = await ethers.getSigners();

            const PaymentSplitter = await (ethers.deployContract("PaymentSplitter_v4", [
                [payee.address],
                [ethers.MaxUint256]
            ],
                {
                    value: ethers.parseUnits("2", "wei")
                }
            ));

            return {PaymentSplitter, payee};
        }

        it("fair-split-eq", async function () {
            const {PaymentSplitter, payee} = await loadFixture(deployContract);

            await expect(PaymentSplitter.release(payee.address))
            .to.be.revertedWithPanic(PANIC_OVERFLOW);
        });
    }

    //     releasable-sum-balance
    {
        async function deployContract() {
            const signers = await ethers.getSigners();

            const payees = [
                signers[0].address,
                signers[1].address,
                signers[2].address];

            const PaymentSplitter = await (ethers.deployContract("PaymentSplitter_v4", [
                payees,
                [1, 1, 1]
            ],
                {
                    value: ethers.parseUnits("4", "wei")
                }));

            return { PaymentSplitter };
        };

        it("releasable-sum-balance", async function () {
            const { PaymentSplitter } = await loadFixture(deployContract);
            const balance = await ethers.provider.getBalance(PaymentSplitter.getAddress());
            const totalReleasable = await PaymentSplitter.getTotalReleasable();

            expect(totalReleasable).not.to.equal(balance);
        })
    };


    //     release-balance-payee

    {
        async function deployContract() {

            const RevertOnReceive = await (ethers.deployContract("RevertOnReceive"))
            const [filler1, filler2] = await ethers.getSigners();

            const payees = [RevertOnReceive.getAddress(), filler1.getAddress(), filler2.getAddress()];
            const shares = [1,1,1];

            const PaymentSplitter = await (ethers.deployContract("PaymentSplitter_v4", [
                payees, shares
            ],
                {
                    value: ethers.parseUnits("100", "wei")
                }));

            return { PaymentSplitter, RevertOnReceive };
        }

        it("release-balance-payee", async function () {
            const { PaymentSplitter, RevertOnReceive } = await loadFixture(deployContract);

            const balanceBefore = await ethers.provider.getBalance(RevertOnReceive.getAddress());

            await PaymentSplitter.release(RevertOnReceive.getAddress());

            const balanceAfter = await ethers.provider.getBalance(RevertOnReceive.getAddress());

            expect(balanceAfter).to.equal(balanceBefore);
        })
    }

    //     release-balance-contract

    {
        async function deployContract() {

            const Returns5 = await (ethers.deployContract("ReturnsN", [5], {
                value: ethers.parseUnits("5", "wei")
            }));
            const [filler1, filler2] = await ethers.getSigners();

            const payees = [Returns5.getAddress(), filler1.getAddress(), filler2.getAddress()];
            const shares = [1,1,1];

            const PaymentSplitter = await (ethers.deployContract("PaymentSplitter_v4", [
                payees, shares
            ],
                {
                    value: ethers.parseUnits("100", "wei")
                }));

            return { PaymentSplitter, Returns5 };
        }

        it("release-balance-contract", async function () {
            const { PaymentSplitter, Returns5 } = await loadFixture(deployContract);

            const balanceBefore = await ethers.provider.getBalance(PaymentSplitter.getAddress());
            
            const amt = await PaymentSplitter.releasable(Returns5.getAddress())
            await PaymentSplitter.release(Returns5.getAddress());

            const balanceAfter = await ethers.provider.getBalance(PaymentSplitter.getAddress());

            expect(balanceAfter).not.to.equal(balanceBefore - amt);
        })
    }


    //     swappable-call-order
    {
        async function deployContract() {

            const Returns7 = await (ethers.deployContract("ReturnsN", [7], {
                value: ethers.parseUnits("7", "wei")
            }));
            const Returns5 = await (ethers.deployContract("ReturnsN", [5], {
                value: ethers.parseUnits("5", "wei")
            }));

            const payees_swap_test = [
                Returns7.getAddress(),
                Returns5.getAddress()
            ];
            const PaymentSplitter = await (ethers.deployContract("PaymentSplitter_v4", [
                payees_swap_test,
                [1, 1]
            ], {
                value: ethers.parseUnits("8", "wei")
            }));

            return { PaymentSplitter, payees_swap_test };
        };

        it("swappable-call-order", async function () {
            var balanceAfter1, balanceAfter2;

            // Run 1: first payee[0] calls release, then payee[1]

            {
                const { PaymentSplitter, payees_swap_test } = await loadFixture(deployContract);

                expect(payees_swap_test[0]).not.to.equal(payees_swap_test[1]);

                await PaymentSplitter.release(payees_swap_test[0]);
                await PaymentSplitter.release(payees_swap_test[1]);

                balanceAfter1 = await ethers.provider.getBalance(PaymentSplitter.getAddress());
            }

            // Run 2: first payee[1] calls release, then payee[0]

            {

                const { PaymentSplitter, payees_swap_test } = await loadFixture(deployContract);

                expect(payees_swap_test[0]).not.to.equal(payees_swap_test[1]);

                await PaymentSplitter.release(payees_swap_test[1]);
                await PaymentSplitter.release(payees_swap_test[0]);

                balanceAfter2 = await ethers.provider.getBalance(PaymentSplitter.getAddress());
            }

            // Confront the two runs
            expect(balanceAfter1).not.to.equal(balanceAfter2);
        });
    };
});