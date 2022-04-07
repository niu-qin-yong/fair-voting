const { ethers } = require("hardhat");
const { expect } = require("chai");
const voteGiftAddress = require("../frontend/src/contracts/VoteGift-Address.json").address;
const Artifact = require("../frontend/src/contracts/VoteGift.json");
const votingAddress = require("../frontend/src/contracts/Voting-Address.json").address;

describe("Ownership",function(){
    it("查看合约VoteGift的owner是否是合约Voting",async function(){
        const provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:7545/");

        const voteGift = new ethers.Contract(voteGiftAddress,Artifact.abi,provider);
        expect(await voteGift.owner()).to.equal(votingAddress);
    });
});

