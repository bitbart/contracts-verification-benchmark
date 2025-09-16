const {
    loadFixture
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

const PANIC_OVERFLOW = 0x11;

describe("PaymentSplitter_v1", function () {


    //     fair-split-eq
    { 
        async function deployContract(){

            const [payee] = await ethers.getSigners();

            const PaymentSplitter = await (ethers.deployContract("PaymentSplitter_v1", [
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
    // release-release-revert
    {
        async function deployContract() {
            // A is a contract with a payable fallback that immediately sends 3 wei to msg.sender
            const A = await (ethers.deployContract("ReturnsN", [3], {
                value: ethers.parseUnits("6", "wei") // it will send 3 two times (once per release(A))
            }));

            const [B, C] = await ethers.getSigners();

            const PaymentSplitter = await ethers.deployContract(
                "PaymentSplitter_v1",
                [[await A.getAddress(), B.address,C.address],[1,1,1]],
                { value: ethers.parseUnits("3", "wei") }
            );

            return { PaymentSplitter, A };
        }

        it("release-release-revert", async function () {
            const { PaymentSplitter, A } = await loadFixture(deployContract);

            // payment = floor((3 + 0) * 1 / 3) - 0 = 1 wei.
            // A will send back 3 wei
            await expect(PaymentSplitter.release(await A.getAddress()))
                .to.not.be.reverted;

            // Assert balance is now 5 wei and totalReleased is 1 wei (if available)
            const balAfter1 = await ethers.provider.getBalance(
                await PaymentSplitter.getAddress()
            );
            expect(balAfter1).to.equal(5n);

            // totalReleased() equals 1 
            if (PaymentSplitter.totalReleased) {
                const tr = await PaymentSplitter.totalReleased();
                expect(tr).to.equal(1n);
            }

            // Without any additional ETH transfers to the splitter, call release(A) again:
            //   releasable(A) = floor((5 + 1) * 1 / 3) - 1 = floor(6/3) - 1 = 2 - 1 = 1 wei > 0
            // So it MUST NOT revert.
            await expect(PaymentSplitter.release(await A.getAddress()))
                .to.not.be.reverted;
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

            const PaymentSplitter = await (ethers.deployContract("PaymentSplitter_v1", [
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

    //     release-not-revert
    {
        async function deployContract() {
            const RevertOnReceive = await (ethers.deployContract("RevertOnReceive"))

            const PaymentSplitter = await (ethers.deployContract("PaymentSplitter_v1", [
                [RevertOnReceive.getAddress()],
                [1]
            ],
                {
                    value: ethers.parseUnits("100", "wei")
                }));

            return { PaymentSplitter, RevertOnReceive };
        };

        it("revert-on-receive", async function () {
            const { PaymentSplitter, RevertOnReceive } = await loadFixture(deployContract);

            const balanceBefore = await ethers.provider.getBalance(PaymentSplitter.getAddress());

            await expect(
                PaymentSplitter.release(RevertOnReceive.getAddress())
            ).to.be.reverted;

            const balanceAfter = await ethers.provider.getBalance(PaymentSplitter.getAddress());

            expect(balanceAfter).to.equal(balanceBefore);
        });
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
            const PaymentSplitter = await (ethers.deployContract("PaymentSplitter_v1", [
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
})