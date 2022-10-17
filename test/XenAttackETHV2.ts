import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import fs from 'fs';
const abi = JSON.parse(fs.readFileSync("/mnt/d/buildSpeace/learnblockchain/xen_batch_mint/scripts/xenAbi.json"));
           
async function increaseTime(value) {
    if (!ethers.BigNumber.isBigNumber(value)) {
      value = ethers.BigNumber.from(value);
    }
    await ethers.provider.send('evm_increaseTime', [value.toNumber()]);
    await ethers.provider.send('evm_mine');
}

describe("xenAttackV2", function () {
    async function deployOneYearLockFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();
        // console.log("owner address: ",owner.address,"otherAccount address: ",otherAccount.address);
        // console.log("owner eth balance: ",ethers.utils.formatEther(await owner.getBalance()));
        // console.log("otherAccount eth balance: ",ethers.utils.formatEther(await otherAccount.getBalance()));

        const xenContractAddress = '0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8';
        const XenAttackV2 = await ethers.getContractFactory("xenAttackV2");
        const xenAttackV2 = await XenAttackV2.deploy(xenContractAddress);

        return { xenAttackV2, owner, otherAccount,xenContractAddress };
    }

    describe("test fork mainner",function(){
        it("get my waller with xen balance",async function(){
            const signer = await ethers.getSigner("0x1fDEbC31fC4f006A3ECb1f0D62f6A2F1BFAeA909")
            const balance = await signer.getBalance();
            console.log(`my waller eth balance: ${ethers.utils.formatEther(balance)} ETH`);
        
            const XenETHAddress =  '0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8';
            const contractXEN =  new ethers.Contract(XenETHAddress ,abi , signer);
            //console.log(contractXEN);
            const userInfo = await contractXEN.userMints(signer.address);
            console.log(userInfo);
            console.log(`userInfo rerm:${userInfo.term}, userInfo rank: ${userInfo.rank}`);
            await expect(userInfo.term).to.be.equal(30);
        });
    });
    describe("Compared xenContract address", function () {
        it("Should batchMint", async function () {
            const { xenAttackV2,xenContractAddress } = await loadFixture(deployOneYearLockFixture);
            //console.log(xenContractAddress);
            expect(await xenAttackV2.xenContractAddress()).to.equal(xenContractAddress);
          });
    });

    // describe("batch mintRank test",function(){
    //     it("batchMint with term < 0 ",async function(){
    //         const { xenAttackV2,owner,otherAccount,xenContractAddress } = await loadFixture(deployOneYearLockFixture);
    //         expect(await xenAttackV2.connect(otherAccount).batchMint(10,-1)).to.be.revertedWith("termDat error!");
    //     });
    // });

    describe("batch Claim test",function(){
        it("batchClaimWithXenContract call",async function(){
            const { xenAttackV2,owner,otherAccount,xenContractAddress } = await loadFixture(deployOneYearLockFixture);
            let tx = await xenAttackV2.connect(otherAccount).batchMint(10,1);
            console.log(tx);
            
            const contractXEN =  new ethers.Contract(xenContractAddress ,abi , otherAccount);
            const userInfo = await contractXEN.userMints(otherAccount.address);
            console.log(userInfo);

           // console.log(`userInfo rerm:${userInfo.term}, userInfo rank: ${userInfo.rank}`);
            // increase and mine time so we can claimReward
            await increaseTime(24*60*60);
            //claim and transfer xen
            await xenAttackV2.connect(otherAccount).batchClaimWithXenContract();

            expect(await contractXEN.balanceOf(otherAccount.address)).to.greaterThan(0);
            console.log("XEN balance: ", ethers.utils.formatEther(await contractXEN.balanceOf(otherAccount.address)).toString());
            
        });
    });

});