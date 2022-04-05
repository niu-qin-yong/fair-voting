
const { ethers } = require("hardhat");

async function main() {
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  // ethers is available in the global scope
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  // deploy
  let voteCoin = await deploy("VoteCoin");
  let voteGift = await deploy("VoteGift");
  let voting = await deploy("Voting",["Satoshi","Vitalik"],voteCoin.address,voteGift.address,ethers.utils.parseEther("0.001"));
  
  // initialize
  voteCoin.instance.mint(voting.address,10000);
  voteGift.instance.transferOwnership(voting.address);

}

async function deploy(contractName,...args){
  const Token = await ethers.getContractFactory(contractName);
  const token = await Token.deploy(...args);
  await token.deployed();

  console.log(contractName + " deployed address:", token.address);

  return {"instance":token,"address":token.address};
}

function saveFrontendFiles(token) {
  const fs = require("fs");
  const contractsDir = __dirname + "/../frontend/src/contracts";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }

  fs.writeFileSync(
    contractsDir + "/contract-address.json",
    JSON.stringify({ token: token.address }, undefined, 2)
  );

  const TokenArtifact = artifacts.readArtifactSync(token);

  fs.writeFileSync(
    contractsDir + "/"+ token +".json",
    JSON.stringify(TokenArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
