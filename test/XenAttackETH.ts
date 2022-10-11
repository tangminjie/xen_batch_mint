import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("xenAttack", function () {
    async function deployOneYearLockFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();
        const xenContractAddress = '0xca41f293A32d25c2216bC4B30f5b0Ab61b6ed2CB';
        const Lock = await ethers.getContractFactory("xenAttack");
        const lock = await Lock.deploy(xenContractAddress);

        return { lock, owner, otherAccount,xenContractAddress };
    }

    describe("batchMint", function () {
        it("Should batchMint", async function () {
            const { lock,xenContractAddress } = await loadFixture(deployOneYearLockFixture);
            //console.log(xenContractAddress);
            expect(await lock.xenContractAddress()).to.equal(xenContractAddress);
          });
    });
});