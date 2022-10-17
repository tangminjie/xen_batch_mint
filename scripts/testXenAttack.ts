import { ethers } from "hardhat";

async function main() {
    const xenContractAddress = '0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8';
    const XENATTACK = await ethers.getContractFactory("xenAttackV2");
    const xenAttack = await XENATTACK.deploy(xenContractAddress);
    await xenAttack.deployed();

    const [owner] = await ethers.getSigners();
    const createAddress =  await xenAttack.testCreate2(owner.address,0);
    console.log(createAddress);
    console.log("#################################");
    const getAddress = await xenAttack.getCreateAddress(owner.address,0);
    console.log(getAddress);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
