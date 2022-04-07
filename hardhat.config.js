require("@nomiclabs/hardhat-waffle");

//ganache账户私钥
const ganache_account_0 = "7db0b1c6e30dcd8b2bddf5b09ee39bad9da91b33f6dd8f67bc96d9b138768277";

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks:{
    "ganache":{
      url:"HTTP://127.0.0.1:7545",
      accounts:[`${ganache_account_0}`]
    }
  }
};
