const { loadFixture, mine } =
    require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LendingProtocol_v9", function () {

    async function deployContract() {
        const [owner, actor_a, actor_b] = await ethers.getSigners();

        const amount = 1000000000000;

        const tok0 = await ethers.deployContract("ERC20", [
            amount
        ], {
            signer: owner
        });

        const tok1 = await ethers.deployContract("ERC20b", [
            amount
        ], {
            signer: owner
        });

        const lp = await ethers.deployContract("LendingProtocol_v9",
            [
                await tok0.getAddress(),
                await tok1.getAddress(),
            ]
        );

        await tok0.transfer(actor_a, 5000000);
        await tok1.transfer(actor_b, 5000000);

        await tok1.transfer(actor_a, 5000000);

        return { lp, tok0, tok1, actor_a, actor_b, owner };
    }

    it("trace1", async function () {
        const { lp, tok0, tok1, actor_a, actor_b, owner } = await loadFixture(deployContract);

        // deployment checks 

        const tok0_addr = await tok0.getAddress();
        const tok1_addr = await tok1.getAddress();


        expect(await lp.tok0()).to.equal(tok0_addr);
        expect(await lp.tok1()).to.equal(tok1_addr);

        expect(await lp.reserves(tok0_addr)).to.equal(0);
        expect(await lp.reserves(tok1_addr)).to.equal(0);

        expect(await lp.getUpdatedSumDebits(tok0_addr)).to.equal(0);
        expect(await lp.getUpdatedSumDebits(tok1_addr)).to.equal(0);

        expect(await lp.sum_debits(tok0_addr)).to.equal(0);
        expect(await lp.sum_debits(tok1_addr)).to.equal(0);


        // step 1; A:deposit(50:T0) 


        const amountDeposit = 50n;

        const reserve_t0_0 = await lp.reserves(tok0_addr);
        const reserve_t1_0 = await lp.reserves(tok1_addr);
        const credit_t0_a_0 = await lp.credit(tok0_addr, actor_a);

        await tok0.connect(actor_a).approve(await lp.getAddress(), amountDeposit);

        await lp.connect(actor_a).deposit(amountDeposit, tok0_addr);

        const reserve_t0_1 = await lp.reserves(tok0_addr);
        const reserve_t1_1 = await lp.reserves(tok1_addr);
        const credit_t0_a_1 = await lp.credit(tok0_addr, actor_a);
        const credit_t1_b_1 = await lp.credit(tok1_addr, actor_b);

        expect(reserve_t0_1).to.equal(reserve_t0_0 + amountDeposit);
        expect(reserve_t1_1).to.equal(reserve_t1_0);
        expect(credit_t0_a_1).to.equal(credit_t0_a_0 + amountDeposit);

        // step 2; B:deposit(50:T1) 

        await tok1.connect(actor_b).approve(await lp.getAddress(), amountDeposit);
        await lp.connect(actor_b).deposit(amountDeposit, tok1_addr);

        const reserve_t0_2 = await lp.reserves(tok0_addr);
        const reserve_t1_2 = await lp.reserves(tok1_addr);
        const credit_t1_b_2 = await lp.credit(tok1_addr, actor_b);

        expect(reserve_t0_2).to.equal(reserve_t0_1);
        expect(reserve_t1_2).to.equal(reserve_t1_1 + amountDeposit);
        expect(credit_t1_b_2).to.equal(credit_t1_b_1 + amountDeposit);

        // step 3; B:borrow(30:T0) 

        const amountBorrow = 30n;

        await lp.connect(actor_b).borrow(amountBorrow, tok0_addr);

        const reserve_t0_3 = await lp.reserves(tok0_addr);
        const reserve_t1_3 = await lp.reserves(tok1_addr);

        expect(reserve_t0_3).to.equal(reserve_t0_2 - amountBorrow)
        expect(reserve_t1_3).to.equal(reserve_t1_2);
    });

    it("trace2", async function () {
        const { lp, tok0, tok1, actor_a, actor_b, owner } = await loadFixture(deployContract);

        // deployment checks / initial state 
        const tok0_addr = await tok0.getAddress();
        const tok1_addr = await tok1.getAddress();

        expect(await lp.tok0()).to.equal(tok0_addr);
        expect(await lp.tok1()).to.equal(tok1_addr);

        expect(await lp.reserves(tok0_addr)).to.equal(0);
        expect(await lp.reserves(tok1_addr)).to.equal(0);

        expect(await lp.getUpdatedSumDebits(tok0_addr)).to.equal(0);
        expect(await lp.getUpdatedSumDebits(tok1_addr)).to.equal(0);

        expect(await lp.sum_debits(tok0_addr)).to.equal(0);
        expect(await lp.sum_debits(tok1_addr)).to.equal(0);


        // step 1; A:deposit(50:T0) 
        const amountDeposit = 50n;

        const reserve_t0_0 = await lp.reserves(tok0_addr);
        const reserve_t1_0 = await lp.reserves(tok1_addr);
        const credit_t0_a_0 = await lp.credit(tok0_addr, actor_a);

        await tok0.connect(actor_a).approve(await lp.getAddress(), amountDeposit);

        await lp.connect(actor_a).deposit(amountDeposit, tok0_addr);

        const reserve_t0_1 = await lp.reserves(tok0_addr);
        const reserve_t1_1 = await lp.reserves(tok1_addr);
        const credit_t0_a_1 = await lp.credit(tok0_addr, actor_a);
        const credit_t1_b_1 = await lp.credit(tok1_addr, actor_b);

        expect(reserve_t0_1).to.equal(reserve_t0_0 + amountDeposit);
        expect(reserve_t1_1).to.equal(reserve_t1_0);
        expect(credit_t0_a_1).to.equal(credit_t0_a_0 + amountDeposit);

        // step 2; B:deposit(50:T1) 
        await tok1.connect(actor_b).approve(await lp.getAddress(), amountDeposit);
        await lp.connect(actor_b).deposit(amountDeposit, tok1_addr);

        const reserve_t0_2 = await lp.reserves(tok0_addr);
        const reserve_t1_2 = await lp.reserves(tok1_addr);
        const credit_t0_a_2 = await lp.credit(tok0_addr, actor_a);
        const credit_t1_b_2 = await lp.credit(tok1_addr, actor_b);
        const debit_t0_b_2 = await lp.getAccruedDebt(tok0_addr, actor_b);

        expect(reserve_t0_2).to.equal(reserve_t0_1);
        expect(reserve_t1_2).to.equal(reserve_t1_1 + amountDeposit);
        expect(credit_t1_b_2).to.equal(credit_t1_b_1 + amountDeposit);

        // step 3; B:borrow(30:T0) 
        const amountBorrow = 30n;

        await lp.connect(actor_b).borrow(amountBorrow, tok0_addr);

        const reserve_t0_3 = await lp.reserves(tok0_addr);
        const reserve_t1_3 = await lp.reserves(tok1_addr);
        const credit_t0_a_3 = await lp.credit(tok0_addr, actor_a);
        const credit_t1_b_3 = await lp.credit(tok1_addr, actor_b);
        const debit_t0_b_3 = await lp.getAccruedDebt(tok0_addr, actor_b);
        const debit_t1_b_3 = await lp.getAccruedDebt(tok1_addr, actor_b);

        expect(reserve_t0_3).to.equal(reserve_t0_2 - amountBorrow);
        expect(reserve_t1_3).to.equal(reserve_t1_2);
        expect(credit_t0_a_3).to.equal(credit_t0_a_2);
        expect(credit_t1_b_3).to.equal(credit_t1_b_2);
        expect(debit_t0_b_3).to.equal(debit_t0_b_2 + amountBorrow);

        // step 4; accrueInt() 
        // snapshot pre-accrual to compare
        const reserve_t0_preAccrue = reserve_t0_3;
        const reserve_t1_preAccrue = reserve_t1_3;

        await mine(1_000_000);
        await lp.connect(owner).accrueInt();

        const reserve_t0_4 = await lp.reserves(tok0_addr);
        const reserve_t1_4 = await lp.reserves(tok1_addr);
        const credit_t0_a_4 = await lp.credit(tok0_addr, actor_a);
        const credit_t1_b_4 = await lp.credit(tok1_addr, actor_b);
        const debit_t0_b_4 = await lp.getAccruedDebt(tok0_addr, actor_b);
        const debit_t1_b_4 = await lp.getAccruedDebt(tok1_addr, actor_b);

        // reserves unchanged by accrual
        expect(reserve_t0_4).to.equal(reserve_t0_preAccrue);
        expect(reserve_t1_4).to.equal(reserve_t1_preAccrue);

        // credits unchanged
        expect(credit_t0_a_4).to.equal(credit_t0_a_3);
        expect(credit_t1_b_4).to.equal(credit_t1_b_3);

        // B's debit after accrual: 30 -> 33 (10%)
        expect(debit_t1_b_4).to.equal(debit_t1_b_3);
        expect(debit_t0_b_4).to.equal(debit_t0_b_3 + 3n);

        // step 5; B:repay(5:T0) 
        const repayAmt = 5n;
        await tok0.connect(actor_b).approve(await lp.getAddress(), repayAmt);
        await lp.connect(actor_b).repay(repayAmt, tok0_addr);

        const reserve_t0_5 = await lp.reserves(tok0_addr);
        const debit_t0_b_5 = await lp.getAccruedDebt(tok0_addr, actor_b);

        // reserves increase by repaid amount; debit decreases by repaid amount
        expect(reserve_t0_5).to.equal(reserve_t0_4 + 5n);
        expect(debit_t0_b_5).to.equal(debit_t0_b_4 - 5n);
    });
});

