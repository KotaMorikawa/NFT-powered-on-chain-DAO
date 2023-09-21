const hre = require("hardhat");

async function sleep(ms) {
  return new Promise((resolver) => setTimeout(resolver, ms));
}

async function main() {
  // Deploy FakeNFTMaketplace
  const nftMarketplace = await hre.ethers.deployContract("FakeNFTMarketplace");
  await nftMarketplace.waitForDeployment();
  console.log("FakeNFTMarketplace deployed to: ", nftMarketplace.target);

  // Deploy CryptoDevsNFT
  const cryptoDevsNFT = await hre.ethers.deployContract("CryptoDevsNFT");
  await cryptoDevsNFT.waitForDeployment();
  console.log("CryptoDevsNFT deployed to: ", cryptoDevsNFT.target);

  // Deploy CryptoDevsDAO
  const amount = hre.ethers.parseEther("1");
  const daoContract = await hre.ethers.deployContract(
    "CryptoDevsDAO",
    [nftMarketplace.target, cryptoDevsNFT.target],
    { value: amount }
  );
  await daoContract.waitForDeployment();
  console.log("CryptoDevsDAO deployed to: ", daoContract.target);

  await sleep(30 * 1000);

  await hre.run("verify:verify", {
    address: nftMarketplace.target,
    constructorArguments: [],
  });

  await hre.run("verify:verify", {
    address: cryptoDevsNFT.target,
    constructorArguments: [],
  });

  await hre.run("verify:verify", {
    address: daoContract.target,
    constructorArguments: [nftMarketplace.target, cryptoDevsNFT.target],
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exit(1);
  });
