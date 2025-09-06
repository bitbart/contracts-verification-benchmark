const { loadFixture, mine } =
    require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LendingProtocol_v2", function () {

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

        const lp = await ethers.deployContract("LendingProtocol_v2",
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

    it("dep-additivity", async function () {
        var balance_tok1_after_1, balance_tok1_after_2;

        // Run 1: first deposit n1, then n2
        {
            const { lp, tok0, tok1, actor_a, actor_b, owner } = await loadFixture(deployContract);
            const lpAddr = await lp.getAddress();
            const tok1_addr = await tok1.getAddress();

            // setup: deposit 10, borrow 10, accrue once
            await tok1.connect(actor_a).approve(lpAddr, 10n);
            await lp.connect(actor_a).deposit(10, tok1_addr);
            await lp.connect(actor_a).borrow(10, tok1_addr);
            await mine(1_000_000);
            await lp.connect(owner).accrueInt();

            //actual POC
            const n1 = 1n;
            const n2 = 1n;

            await tok1.connect(actor_a).approve(lpAddr, n1 + n2);

            await lp.connect(actor_a).deposit(n1, tok1_addr);
            await lp.connect(actor_a).deposit(n2, tok1_addr);

            balance_tok1_after_1 = await lp.credit(tok1_addr, actor_a);

        }

        // Run 2: deposit n1+n2
        {
            const { lp, tok0, tok1, actor_a, actor_b, owner } = await loadFixture(deployContract);
            const lpAddr = await lp.getAddress();
            const tok1_addr = await tok1.getAddress();

            // setup: deposit 10, borrow 10, accrue once
            await tok1.connect(actor_a).approve(lpAddr, 10n);
            await lp.connect(actor_a).deposit(10, tok1_addr);
            await lp.connect(actor_a).borrow(10, tok1_addr);
            await mine(1_000_000);
            await lp.connect(owner).accrueInt();

            //actual POC
            const n1 = 1n;
            const n2 = 1n;

            await tok1.connect(actor_a).approve(lpAddr, n1 + n2);
            await lp.connect(actor_a).deposit(n1 + n2, tok1_addr);

            balance_tok1_after_2 = await lp.credit(tok1_addr, actor_a.getAddress());
        }

        expect(balance_tok1_after_1).to.not.equal(balance_tok1_after_2);

    });

    it("dep-xr-eq", async function () {

        const { lp, tok0, tok1, actor_a, actor_b, owner } = await loadFixture(deployContract);

        await tok0.connect(actor_a).approve(await lp.getAddress(), 11);

        const actor_a_conn = lp.connect(actor_a);
        const tok0_addr = await tok0.getAddress();

        await actor_a_conn.deposit(10, tok0_addr); // res=10,tot_cred=10,tot_deb=0,xr=1e6
        await actor_a_conn.borrow(10, tok0_addr); // res=0,tot_cred=10,tot_deb=10,xr=1e6 
        await mine(1_000_000);
        await lp.connect(owner).accrueInt(); //res=0,tot_cred=10,tot_deb=11,xr=1.1e6

        const old_xr_t0 = await lp.XR(tok0); //1e6

        await actor_a_conn.deposit(1, tok0_addr); // rounding error
        //res=1,tot_cred=floor(1*1e6/1.1e6)= floor(0.9) = 0, tot_deb=11, xr=1.2e6
        //wasted deposit, not enough to convert to an integer amount of credits
        const new_xr_t0 = await lp.XR(tok0);

        expect(new_xr_t0).not.to.equal(old_xr_t0);
    });

    it("rdm-additivity", async function () {
        var balEnd1, balEnd2;

        // Run 1: first redeem n1, then n2
        {
            const { lp, tok0, tok1, actor_a, actor_b, owner } = await loadFixture(deployContract);
            const lpAddr = await lp.getAddress();

            //preparing pre-state
            await tok0.connect(actor_a).approve(lpAddr, 20n);
            await lp.connect(actor_a).deposit(20n, tok0);
            const bigColl = 1000n;
            await tok1.connect(actor_b).approve(lpAddr, bigColl);
            await lp.connect(actor_b).deposit(bigColl, tok1);
            await lp.connect(actor_b).borrow(10n, tok0);
            await mine(3 * 1_000_000);

            // actual POC
            const a = 1n;
            const b = 6n;

            await lp.connect(actor_a).redeem(a, tok0);
            await lp.connect(actor_a).redeem(b, tok0);
            balEnd1 = await tok0.balanceOf(actor_a);
        }
        // Run 2: redeem n1+n2
        {
            const { lp, tok0, tok1, actor_a, actor_b, owner } = await loadFixture(deployContract);
            const lpAddr = await lp.getAddress();

            //preparing pre-state
            await tok0.connect(actor_a).approve(lpAddr, 20n);
            await lp.connect(actor_a).deposit(20n, tok0);
            const bigColl = 1000n;
            await tok1.connect(actor_b).approve(lpAddr, bigColl);
            await lp.connect(actor_b).deposit(bigColl, tok1);
            await lp.connect(actor_b).borrow(10n, tok0);
            await mine(3 * 1_000_000);

            // actual POC
            const a = 1n;
            const b = 6n;

            await lp.connect(actor_a).redeem(a + b, tok0);

            balEnd2 = await tok0.balanceOf(actor_a);
        }

        expect(balEnd1).to.not.equal(balEnd2);
    });

    it("rdm-xr-eq", async function () {
        const { lp, tok0, actor_a, owner } = await loadFixture(deployContract);

        const lpAddr = await lp.getAddress();
        const tok0_addr = await tok0.getAddress();

        await tok0.connect(actor_a).approve(lpAddr, 100);

        await lp.connect(actor_a).deposit(11, tok0_addr);     // reserves=11, credits=11, debits=0, XR=1e6

        await lp.connect(actor_a).borrow(10, tok0_addr);      // reserves=1, credits=11, debits=10, XR still 1e6

        await mine(1_000_000);
        await lp.connect(owner).accrueInt();                  // reserves=1, credits=11, debits=11, XR=floor(12/11*1e6)=1_090_909

        const oldXR = await lp.XR(tok0_addr);

        await lp.connect(actor_a).redeem(1, tok0_addr);       // tokensOut=floor(1*1_090_909/1e6)=1
        // state: reserves=0, credits=10, debits=11 → XR=floor(11/10*1e6)=1_100_000
        const newXR = await lp.XR(tok0_addr);

        expect(newXR).not.to.equal(oldXR);               // 1_100_000 > 1_090_909
    });

});

