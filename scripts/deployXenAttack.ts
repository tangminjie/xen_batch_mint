import { ethers } from "hardhat";
import fs from 'fs';

async function main() {
    const xenContractAddress = '0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8';
    const XENATTACK = await ethers.getContractFactory("xenAttack");
    const xenAttack = await XENATTACK.deploy(xenContractAddress);
    await xenAttack.deployed();

    console.log("xenAttack deployed to:", xenAttack.address);

    const [owner, otherAccount] = await ethers.getSigners();
    let tx = await xenAttack.connect(otherAccount).batchMint(10,1);
    await tx.wait();
    console.log(tx);

    const XenETHAddress =  '0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8';
    const abi = JSON.parse(fs.readFileSync("/mnt/d/buildSpeace/learnblockchain/xen_batch_mint/scripts/xenAbi.json"));
    const contractXEN =  new ethers.Contract(XenETHAddress ,abi , otherAccount);
    const userInfo = await contractXEN.userMints(otherAccount.address);
    console.log(userInfo);
    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
