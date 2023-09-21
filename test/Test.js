const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  mine,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");

describe("DAO test", async function () {
  async function preset() {
    const [owner] = await ethers.getSigners();
    const nftMarketplace = await ethers.deployContract("FakeNFTMarketplace");
    const cryptoDevsNFT = await ethers.deployContract("CryptoDevsNFT");

    const amount = hre.ethers.parseEther("1");

    const daoContract = await ethers.deployContract(
      "CryptoDevsDAO",
      [nftMarketplace.target, cryptoDevsNFT.target],
      { value: amount }
    );

    return { owner, nftMarketplace, cryptoDevsNFT, daoContract };
  }

  it("purchase test", async function () {
    const { owner, nftMarketplace, cryptoDevsNFT, daoContract } =
      await loadFixture(preset);

    //set DaoContract to nftMarketplace
    await nftMarketplace.setDAOContract(daoContract.target);

    // mint CryptoDevsNFT twice
    await cryptoDevsNFT.connect(owner).mint();
    await cryptoDevsNFT.connect(owner).mint();

    // create proposal
    await daoContract.connect(owner).createProposal(0);

    // vote proposal
    await daoContract.connect(owner).voteProposal(0, 0);

    // time spending
    await mine(1000);

    await daoContract.connect(owner).executeProposal(0);

    expect(await daoContract.checkProposalExecute(0)).equal(true);
  });
});
