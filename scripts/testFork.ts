

import { ethers } from 'hardhat';
import "@nomiclabs/hardhat-ethers";
import fs from 'fs';

const testFork = async () => {
    const signer = await ethers.getSigner("0x1fDEbC31fC4f006A3ECb1f0D62f6A2F1BFAeA909")
    const balance = await signer.getBalance();
    console.log(`my waller eth balance: ${ethers.utils.formatEther(balance)} ETH`);

    const XenETHAddress =  '0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8';
    const abi = JSON.parse(fs.readFileSync("/mnt/d/buildSpeace/learnblockchain/xen_batch_mint/scripts/xenAbi.json"));
    const contractXEN =  new ethers.Contract(XenETHAddress ,abi , signer);
    //console.log(contractXEN);
    const userInfo = await contractXEN.userMints(signer.address);
    console.log(userInfo);
    console.log(`userInfo rerm:${userInfo.term}, userInfo rank: ${userInfo.rank}`);
  }

testFork()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});
