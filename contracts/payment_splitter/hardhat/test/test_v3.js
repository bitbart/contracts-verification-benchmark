const {
    loadFixture
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

const PANIC_OVERFLOW = 0x11;

describe("PaymentSplitter_v3", function () {

    //     fair-split-eq
    { 
        async function deployContract(){

            const [payee, tmp1, tmp2] = await ethers.getSigners();

            const PaymentSplitter = await (ethers.deployContract("PaymentSplitter_v3", [
                payee.address,
                tmp1,
                tmp2
            ],
                {
                    value: ethers.parseUnits("3", "wei")
                }
            ));

            return {PaymentSplitter, payee};
        }

        it("fair-split-eq", async function () {
            const {PaymentSplitter, payee} = await loadFixture(deployContract);

            await PaymentSplitter.release(payee.address);
           
            // totalReleased is now 1; if PaymentSplitter balance is maxed,
            // when balance + totalReleased is calculated, an overflow will happen

            const targetBalance = ethers.MaxUint256;
            
            await network.provider.send("hardhat_setBalance", [
                await PaymentSplitter.getAddress(),
                ethers.toBeHex(targetBalance) 
            ]);

            await expect(PaymentSplitter.release(payee.address))
            .to.be.revertedWithPanic(PANIC_OVERFLOW);
        });
    }

    {
        async function deployContract() {
            const RevertOnReceive = await (ethers.deployContract("RevertOnReceive"))
            const [filler1, filler2] = await ethers.getSigners();

            const PaymentSplitter3 = await (ethers.deployContract("PaymentSplitter_v3", [
                RevertOnReceive.getAddress(),
                filler1.getAddress(),
                filler2.getAddress(),
            ],
                {
                    value: ethers.parseUnits("100", "wei")
                }));

            return { PaymentSplitter3, RevertOnReceive };
        };

        it("release-not-revert", async function () {
            const { PaymentSplitter3, RevertOnReceive } = await loadFixture(deployContract);

            const balanceBefore = await ethers.provider.getBalance(PaymentSplitter3.getAddress());

            await expect(
                PaymentSplitter3.release(RevertOnReceive.getAddress())
            ).to.be.reverted;

            const balanceAfter = await ethers.provider.getBalance(PaymentSplitter3.getAddress());

            expect(balanceAfter).to.equal(balanceBefore);
        });
    }

    {
        async function deployContract() {
            const [filler1, filler2, filler3] = await ethers.getSigners();

            const PaymentSplitter3 = await (ethers.deployContract("PaymentSplitter_v3", [
                filler1.getAddress(),
                filler2.getAddress(),
                filler3.getAddress()
            ],
                {
                    value: ethers.parseUnits("4", "wei")
                }));

            return { PaymentSplitter3 };
        };

        it("Releasable sum balance", async function () {
            const { PaymentSplitter3 } = await loadFixture(deployContract);
            const balance = await ethers.provider.getBalance(PaymentSplitter3.getAddress());
            const totalReleasable = await PaymentSplitter3.getTotalReleasable();

            expect(totalReleasable).not.to.equal(balance);
        })
    }

    {
        async function deployContract() {

            const Returns7 = await(ethers.deployContract("ReturnsN", [7], {
                value: ethers.parseUnits("7", "wei")
            }));
            const Returns5 = await(ethers.deployContract("ReturnsN", [5], {
                value: ethers.parseUnits("5", "wei")
            }));

            const payees_swap_test = [
                Returns7.getAddress(),
                Returns5.getAddress()
            ];
            const [payee3] = await ethers.getSigners();
            const PaymentSplitter = await(ethers.deployContract("PaymentSplitter_v3", [
                payees_swap_test[0],
                payees_swap_test[1],
                payee3.getAddress(),
            ], {
                value: ethers.parseUnits("8", "wei")
            }));

            return { PaymentSplitter, payees_swap_test };
        };

        it("Call order is not swappable", async function () {
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
    }
});