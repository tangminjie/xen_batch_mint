import { ethers } from "hardhat";
import fs from 'fs';

async function increaseTime(value) {
  if (!ethers.BigNumber.isBigNumber(value)) {
    value = ethers.BigNumber.from(value);
  }
  await ethers.provider.send('evm_increaseTime', [value.toNumber()]);
  await ethers.provider.send('evm_mine');
}


async function main() {
    const xenContractAddress = '0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8';
    const XENCALL = await ethers.getContractFactory("xenCall");
    const xenCall = await XENCALL.deploy(xenContractAddress);
    await xenCall.deployed();

    console.log("xenAttack deployed to:", xenCall.address);
    console.log("xenCall owner: ",await xenCall.owner());
    
    const [owner, otherAccount] = await ethers.getSigners();
    let tx = await xenCall.connect(otherAccount).callXenWithMint(1);
    await tx.wait();
    console.log(tx);
    
    const XenETHAddress =  '0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8';
    const abi = JSON.parse(fs.readFileSync("/mnt/d/buildSpeace/learnblockchain/xen_batch_mint/scripts/xenAbi.json"));
    const contractXEN =  new ethers.Contract(XenETHAddress ,abi , owner);
    const userInfo = await contractXEN.userMints(xenCall.address);
    console.log(userInfo);

    await increaseTime(48*60*60);
    tx = await xenCall.connect(otherAccount).callXenWithClaim();
    await tx.wait();

    const xencallBalance = await contractXEN.balanceOf(xenCall.address);
    console.log("xenCallBalance: ",xencallBalance);

    tx = await xenCall.reward(otherAccount.address,10000);
    await tx.wait();

    console.log("otherAccountBalance: ",ethers.utils.formatEther(
      await contractXEN.balanceOf(otherAccount.address)
    ));

    tx = await xenCall.connect(owner).withdrawEmergency(otherAccount.address);
    await tx.wait();

    console.log("otherAccountBalance: ",ethers.utils.formatEther(
      await contractXEN.balanceOf(otherAccount.address)
    ));
    
    // const otherAccountBalance = await contractXEN.balanceOf("0x716160692303c9ef681ee7619c87f464c01b6ba7");
    // console.log("otherAccountBalance: ",ethers.utils.formatEther(otherAccountBalance));

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
