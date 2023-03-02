require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-ethers");
require("@nomicfoundation/hardhat-toolbox");
require('hardhat-deploy');
require("@nomicfoundation/hardhat-chai-matchers");
require('solidity-coverage');
//require('dotenv').config();


module.exports = {
  solidity: "0.8.17",
  namedAccounts: {
    deployer1: 0,
    deployer2: 1,
    deployer3: 2,
    deployer4: 3
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/CR0jZfJoRngGFWeFojtEY23kLF9YijMA",
        blockNumber: 13414215
      }
    }
  }
};