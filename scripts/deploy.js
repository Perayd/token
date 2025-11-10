const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying from:", deployer.address);

  const initialSupply = ethers.utils.parseUnits("1000000", 18); // 1,000,000 MTK

  const MyToken = await ethers.getContractFactory("MyToken");
  const token = await MyToken.deploy(initialSupply);
  await token.deployed();
  console.log("MyToken deployed to:", token.address);

  // deploy staking with initial reward rate (e.g., 1 MTK per second)
  const rewardRatePerSecond = ethers.utils.parseUnits("1", 18); // 1 MTK/s
  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(token.address, rewardRatePerSecond);
  await staking.deployed();
  console.log("Staking deployed to:", staking.address);

  // (Optional) transfer some tokens to staking contract as initial rewards
  const topUp = ethers.utils.parseUnits("10000", 18);
  let tx = await token.transfer(staking.address, topUp);
  await tx.wait();
  console.log(`Transferred ${topUp.toString()} MTK to staking contract`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
