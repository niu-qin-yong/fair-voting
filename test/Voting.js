const { ethers } = require("hardhat");
const chai = require("chai");
const expect = chai.expect;
const assertArrays = require('chai-arrays');

const votingArtifact = require("../frontend/src/contracts/Voting.json");
const votingAddress = require("../frontend/src/contracts/Voting-Address.json").address;
const voteCoinArtifact = require("../frontend/src/contracts/VoteCoin.json");
const voteCoinAddress = require("../frontend/src/contracts/VoteCoin-Address.json").address;

chai.use(assertArrays);

let provider;
let voting;
let voteCoin;
let price;
let signerAddress;

before(async function(){
    provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545/");
    voting = new ethers.Contract(votingAddress,votingArtifact.abi,provider.getSigner(1));
    voteCoin = new ethers.Contract(voteCoinAddress,voteCoinArtifact.abi,provider.getSigner(1));

    price = await voting.tokenPrice();
    signerAddress = voting.signer.getAddress();
});

describe("init",function(){
    it("候选人初始化正确",async function(){
        let candidates = await voting.getCandidates();
        expect(candidates).to.be.equalTo([ 'Satoshi', 'Vitalik' ]);
    })

    it("VTC token price初始化正确",async function(){
        expect(await voting.tokenPrice()).to.be.equal(ethers.utils.parseEther("0.001"));
    });
});

describe("Buy",function(){
    
    it("购买VTC,交易双方VTC余额正确",async function(){
        let val = ethers.BigNumber.from(String(price * 10));
        expect(async () => await voting.buy(10,{value:val})).to
        .changeTokenBalance(voteCoin,voting.signer,10);
    });

    it("购买VTC,触发了Buy事件",async function(){
        let val = ethers.BigNumber.from(String(price * 19));
        expect(async () => await voting.buy(19,{value:val})).to.emit(voting,'Buy')
        .withArgs(signerAddress,19);
    });

    it("同一地址,1分钟内只允许购买1次",async function(){
        console.log("token balance before:" + await voteCoin.balanceOf(signerAddress));

        await voting.buy(2,{value:ethers.BigNumber.from(String(price * 2))});
        await expect(voting.buy(3,{value:ethers.BigNumber.from(String(price * 3))}))
        .to.be.revertedWith('only buy once within a minute');

        console.log("token balance after:" + await voteCoin.balanceOf(signerAddress));
    });
});

describe("addCandidate",function(){
    it("成功添加候选人",async function(){
        //connect to the contract owner
        console.log("owner: "+ await voting.owner());
        console.log("addr0: " + await provider.getSigner(0).getAddress());
        voting = voting.connect(provider.getSigner(0));

        let before = await voting.getCandidates();
        let shouldBe = Object.assign([],before);

        await voting.addCandidate(['Gavin Wood']);
        let current = await voting.getCandidates();

        shouldBe.push('Gavin Wood');

        expect(current).to.be.equalTo(shouldBe);
    });
});

describe("setVotingTime",function(){
    it("成功设置投票开始时间和时长",async function(){
        //connect to the contract owner
        voting = voting.connect(provider.getSigner(0));

        let number = await provider.getBlockNumber();
        let block = await provider.getBlock(number);

        let period = 3600;
        let startTime = block.timestamp + 300;

        await expect(voting.setVotingTime(ethers.BigNumber.from(String(startTime)),period)).to.emit(voting,'SetVotingTime')
        .withArgs(ethers.BigNumber.from(String(startTime)),period,ethers.BigNumber.from(String(startTime + period)));

    });
});

describe("vote",function(){
    it("投票后代币VTC余额变化正确",async function(){
        //注意:请先完成设置投票开始时间,购买VTC代币,授权给Voting合约等前置操作
        await expect(() => voting.vote(1,10)).to
            .changeTokenBalance(voteCoin,provider.getSigner(1),-10);
    })

    it("投票后候选人票数变化正确", async function(){
        let before = await voting.getVotesForCandidate(1);
        let votes = 2;
        await voting.vote(1,votes);
        expect(await voting.getVotesForCandidate(1)).to.be.equal(Number(before) + votes);
    })
});