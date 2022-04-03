// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./VoteCoin.sol";
import "./VoteGift.sol";
import "./IVoting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is IVoting, Ownable{
    //unit wei
    uint256 public tokenPrice;
    //投票开始时间
    uint256 private _timeStart;
    //投票结束时间
    uint256 private _timeEnd;
    //候选人列表
    string[] private _candidateList;
    //记录上次购买VTC的时间
    mapping (address => uint256) private _buyLastTime;
    //记录候选人得票情况
    mapping (uint8 => uint256) private _candidatesVotesReceived;
    //记录voter给候选人投的票数
    mapping (address => mapping (uint8 => uint256)) private _voterVotesDistribution;
    //记录voter都给哪些候选人投过票(因为mapping不支持遍历key,所以维护一个数组来保存key)
    mapping (address => uint8[]) private _voterVoteWho;
    //在函数getVoterInfo中使用,用于保存voter投票过的候选人和对其所投票数
    uint256[] private _votes;
    //记录是否是voter,只有voter才能mint NFT
    mapping (address => bool) private _hasVoted;
    //记录是否已经mint过,一个地址只允许mint一个
    mapping (address => bool) private _hasMinted;
    VoteCoin private _token;
    VoteGift private _nftToken;

    /* 
     * @description: 先部署VoteCoin和votingCommemoration,拿到它们的合约地址后,再来部署Voting
     */
    constructor(string[] memory candidateList,address vtcContractAddress,address ntfContractAddress,uint256 pricePerToken) {
        _candidateList = candidateList;
        _token = VoteCoin(vtcContractAddress);
        _nftToken = VoteGift(ntfContractAddress);
        tokenPrice = pricePerToken;
    }

    /*
     * @description: 给下标是candidateIndex的候选人投tokenToVote票
     * @param {uint8} candidateIndex 候选人在候选人列表中的下标
     * @param {uint256} tokenToVote 投的token数量
     * @return {*}
     */
    function vote(uint8 candidateIndex,uint256 tokenToVote) public override {
        require(_timeStart != 0,"voting doesn't start yet");
        require(block.timestamp < _timeEnd,"voting has stopped");
        require(candidateIndex >= 0 && candidateIndex < _candidateList.length,"candidateIndex is wrong");
        require(tokenToVote > 0,"vote 1 _token at least");
        require(_token.balanceOf(_msgSender()) >= tokenToVote,"not enough token to vote");
        require(_token.allowance(_msgSender(), address(this)) >= tokenToVote,"not enough allowance to vote");

        _candidatesVotesReceived[candidateIndex] += tokenToVote;
        //第一次给某个候选人投票,将候选人index添加到key数组
        if(_voterVotesDistribution[_msgSender()][candidateIndex] == 0){
            _voterVoteWho[_msgSender()].push(candidateIndex);
        }
        _voterVotesDistribution[_msgSender()][candidateIndex] += tokenToVote;
        _hasVoted[_msgSender()] = true;
        _token.burnFrom(_msgSender(),tokenToVote);

        emit Vote(_msgSender(), _candidateList[candidateIndex], tokenToVote);
    }

    /*
     * @description: 设置投票开始时间和投票时长,要求开始时间不能晚于当前区块时间
     * @param {uint256} timeStart
     * @return {*}
     */
    function setVotingTime(uint256 timeStart,uint256 period) public override onlyOwner{
        require(timeStart > block.timestamp,"the time voting starts should be later than now");
        _timeStart = timeStart;
        _timeEnd = _timeStart + period;

        emit SetVotingTime(_timeStart, period, _timeEnd);
    }

    /*
     * @description: 使用eth购买VTC,单价0.01eth/VTC
     * 只能购买1的整数倍,,且每次最多能买100个,且1分钟之内只能购买1次(避免某个人买下所有token)
     * @param {*}
     * @return {*}
     */
    function buy(uint256 amount) public override payable{
        require(amount <= 100,"amount exceeds 100");
        require(tokenPrice * amount == msg.value,"the value paid should equal bought");
        require(buyTimeCheck(block.timestamp),"only buy once within a minute");
        uint256 availableAmount = _token.balanceOf(address(this));
        string memory half = concat("there are only ", Strings.toString(availableAmount));
        string memory noEnough2Buy = concat(half, " VTC available to buy");
        require(availableAmount >= amount, noEnough2Buy);

        _token.transfer(_msgSender(), amount);

        _buyLastTime[_msgSender()] = block.timestamp;

        emit Buy(_msgSender(), amount);
    }

    function concat(string memory _base, string memory _value) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        bytes memory _newValue =  new bytes(_baseBytes.length + _valueBytes.length);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /*
     * @description: 同一地址要求一分钟内只能购买一次
     * @param {uint256} timeNow
     * @return {*}
     */
    function buyTimeCheck(uint256 timeNow) internal view returns(bool){
        uint256 lastTime = _buyLastTime[_msgSender()];
        if(timeNow - lastTime > 1 minutes){
            return true;
        }
        return false;
    }


    /*
     * @description: 购买的VTC未用于投票,可以发送给合约,原价返还之前购买花费
     * @param {uint256} amount
     * @param {bytes} memory
     * @return {*}
     */
    function sell(uint256 amount) public override returns(bool , bytes memory){
        uint256 tokenBalance = _token.balanceOf(_msgSender());
        require(tokenBalance >= amount,"sell amount exceeds balance");

        uint256 currentAllowance = _token.allowance(_msgSender(),address(this));
        require(currentAllowance >= amount,"sell amount exceeds allowance");

        _token.transferFrom(_msgSender(), address(this), amount);
        uint256 paybackValue = tokenPrice * amount;
        (bool success,bytes memory data) = payable(_msgSender()).call{value:paybackValue}("");
        
        emit Sell(_msgSender(), amount);
        
        return (success,data);
    }

    /*
     * @description: 获取合约内的eth余额
     * @param {public view} returns
     * @return {*}
     */    
    function getBalance(address addr) public view returns(uint) {
        return address(addr).balance;
    }

    /*
     * @description: 投票结束后可以进行捐赠
     * 假设 0xaC505f34fbC475E6316d49Da077A2BAB3907a45e 是一个慈善组织的地址
     * @param {*}
     * @return {*}
     */
    function donate() public override onlyOwner{
        require(_timeStart != 0,"voting doesn't start yet");
        require(block.timestamp > _timeEnd,"voting doesn't end yet");
        uint256 balance = address(this).balance;
        require(balance > 0,"no fund to donate");

        address payable addr = payable(address(0xaC505f34fbC475E6316d49Da077A2BAB3907a45e));
        selfdestruct(addr);

        emit Donate(addr, block.timestamp, balance);
    }

    /*
     * @description: 获取候选人得票情况
     * @param {uint8} candidateIndex
     * @return {*}
     */    
    function getVotesForCandidate(uint8 candidateIndex) public view override returns(uint256){
        return _candidatesVotesReceived[candidateIndex];
    }

    /*
     * @description:清空数组_votes中的数据,每次getVoterInfo执行完后执行
     */    
    modifier clearVotes(){
        _;
        delete _votes;
    }

    /*
     * @description: 返回地址voterAddress持有的VTC数量和给哪些候选人投多多少票,
     * 注意:返回的数组votes中奇数下标是候选人index,接下来的偶数下标是该候选人的票数
     * @param {address} voterAddress
     * @param {uint256[]} memory
     * @return {*}
     */
    function getVoterInfo(address voterAddress) public override clearVotes returns(uint256,uint256[] memory) {
        uint256 tokenBalance = _token.balanceOf(voterAddress);
        for(uint8 i = 0;i < _voterVoteWho[voterAddress].length;i++){
            uint8 candidateIndex = _voterVoteWho[voterAddress][i];
            _votes.push(candidateIndex);
            uint256 voteAmount = _voterVotesDistribution[voterAddress][candidateIndex];
            _votes.push(voteAmount);
        }
        return (tokenBalance,_votes);
    }

    /*
     * @description: 添加候选人
     * @param {string memory} candidate
     * @return {*}
     */
    function addCandidate(string[] memory candidates) public override onlyOwner{
        for(uint8 i = 0; i < candidates.length; i++){
            _candidateList.push(candidates[i]);
        }

        emit AddCandidate(candidates, _candidateList);
    }

    /*
     * @description: 获取候选人列表
     * @param {public view} returns
     * @return {*}
     */    
    function getCandidates() public override view returns (string[] memory){
        return _candidateList;
    }

    /*
     * @description: 投票地址有资格mint一个NFT
     * @param {*}
     * @return {*}
     */
    function mintNFT() public override {
        require(_hasVoted[_msgSender()],"only the voter can mint");
        require(!_hasMinted[_msgSender()],"a voter can only mint once");

        string memory uri = "https://cdn.dribbble.com/users/273990/screenshots/5519988/thanks-for-voting.jpg";
        _nftToken.safeMint(_msgSender(), uri);

        _hasMinted[_msgSender()] = true;

        emit MintNFT(_msgSender(), _nftToken.ownWhichOne(_msgSender()));
    }

}