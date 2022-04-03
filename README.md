# 一个特别的投票dapp

母校学生会准备进行选举,为了选举的公开透明,我特地穿越回去写了此dapp.

## 主要功能
- 选举投票要使用专用的ERC20代币VTC,1VTC=1票,投票的VTC会被销毁.
- 合约owner可以设置投票开始时间和时长.
- VTC需要使用eth购买,每个地址每次最多只能购买100枚,且1分钟内只能买1次(避免被少数地址全部买走)
- 合约提供回购功能,没有用于投票的VTC可以按原价再卖给合约.
- 合约部署时可以初始化候选人,部署后也可以再次添加候选人.
- 可以查询候选人有哪些,以及他们的得票情况.
- 可以查询某个地址当前持有的VTC数量,以及其给哪些候选人投了多少票.
- 参与投票的地址有资格mint一枚NFT.
- 投票结束后可以将出售VTC所得捐赠给慈善组织,之后自动销毁合约.

## 合约使用注意事项

1. 首先部署ERC20代币合约VoteCoin和ERC721代币合约VoteGift.

2. 然后部署合约Voting,构造函数中传递参数:候选人列表,VoteCoin的合约地址,VoteGift的合约地址,VTC的价格(单位wei),主要逻辑实现在Voting中完成.

3. 3个合约都部署完成后,VoteCoin合约的owner调用mint函数,给合约Voting mint一定数量的VTC代币,这样Voting就有币可出售了.VoteGift合约的owner调用的ransferOwnership函数,将合约owner转让给Voting,这样Voting就可以给合格的地址mint NFT了.

上面步骤完成后,就可以正常使用合约了.以上步骤在 deploy.js 中自动完成.

## 环境支持

- [Hardhat](https://hardhat.org/)
- [openzeppelin](https://docs.openzeppelin.com/contracts/4.x/)
- [Mocha](https://mochajs.org/)
- [Chai](https://www.chaijs.com/)
- [ethers.js](https://docs.ethers.io/v5/)
- [Waffle](https://github.com/EthWorks/Waffle/)

