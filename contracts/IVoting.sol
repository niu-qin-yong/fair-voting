
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IVoting {

    /**
     * 投票时触发
     */
    event Vote(address voter,string candidate,uint256 votes);

    /*
     * @description: 设置投票时间时触发
     */    
    event SetVotingTime(uint256 timeStart,uint256 period,uint256 timeEnd);

    /*
     * @description: voter购买VTC时触发
     */    
    event Buy(address buyer,uint256 amount);

    /*
     * @description: 合约回购未用于投票的VTC时触发
     */    
    event Sell(address seller,uint256 amount);

     /*
     * @description: 合约余额进行捐赠时触发
     */    
    event Donate(address recipient,uint256 donateTime,uint256 donateAmount);   

     /*
     * @description: 添加候选人时触发
     */    
    event AddCandidate(string[] newCandidates,string[] totalCandidates);  

    /*
     * @description: mint VoteGift 时触发
     */    
    event MintNFT(address voter,uint256 tokenId);  
      
    /**
     * 给下标是`candidateIndex`的候选人投`tokenToVote`票
     *
     * 触发一个 {Vote} 事件  
     */
    function vote(uint8 candidateIndex,uint256 tokenToVote) external;

    /*
     * @description: 设置投票开始时间和投票时长
     * 
     * 要求:
     * 只允许合约 owner 执行
     *
     * 触发一个 {SetVotingTime} 事件
     */    
    function setVotingTime(uint256 timeStart,uint256 period) external;

    /*
     * @description: 投票者购买投票专用ERC20 token VTC
     *
     * 要求:
     * 只能购买1的整数倍,且每次最多能买100个,且1分钟之内只能购买1次(避免某个人买下所有token)
     *
     * 触发一个 {Buy} 事件
     */
    function buy(uint256 amount) external payable;

    /*
     * @description:合约可以原价回购未用于投票的VTC
     *
     * 触发一个 {Sell} 事件
     */    
    function sell(uint256 amount) external returns(bool , bytes memory);

    /*
     * @description: 投票结束后,将出售VTC所得捐赠给慈善组织,捐赠完成后自动销毁合约
     *
     * 要求:
     * 只允许合约 owner 执行
     * 
     * 触发一个 {Donate} 事件
     */
    function donate() external;

    /*
     * @description: 获取下标是 `candidateIndex` 的候选人的得票数
     */
    function getVotesForCandidate(uint8 candidateIndex) external view returns(uint256);

    /*
     * @description: 获取地址 `voterAddress` 的信息,包括当前持有的VTC的数量和给哪些候选人投了多少票
     */
    function getVoterInfo(address voterAddress) external returns(uint256,uint256[] memory) ;

    /*
     * @description: 增加候选人
     *
     * 触发一个 {AddCandidate} 事件
     */
    function addCandidate(string[] memory candidates) external;

    /*
     * @description: 获取所有候选人
     */
    function getCandidates() external view returns (string[] memory);

    /*
     * @description: 投票地址有资格mint一个NFT
     *
     * 触发一个 {MintNFT} 事件
     */    
    function mintNFT() external;
}