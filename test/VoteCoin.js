const { ethers } = require("hardhat");
const { expect } = require("chai");
const voteCoinAddress = require("../frontend/src/contracts/VoteCoin-Address.json").address;
const Artifact = require("../frontend/src/contracts/VoteCoin.json");
const votingAddress = require("../frontend/src/contracts/Voting-Address.json").address;

let provider;
let voteCoin;

before(function(){
    provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:7545/");
    voteCoin = new ethers.Contract(voteCoinAddress,Artifact.abi,provider.getSigner(1));
});

describe("Balance",function(){
    it("非合约owner,不能mint代币",async function(){
        console.log("owner:"+await voteCoin.owner());

        let signer = await voteCoin.signer;
        console.log("signer:"+ await signer.getAddress());

        await expect(voteCoin.mint(votingAddress,10)).to.be.reverted;
    });

    it("查看Voting中的VTC余额是否等于10000",async function(){
        const balance = await voteCoin.balanceOf(votingAddress);
        expect(balance).to.equal(10000);
    });
});

