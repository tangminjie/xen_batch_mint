import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";
import 'solidity-coverage';
require("dotenv").config({ path: "./hardhat-tutorial.env" });

const GOERLI_API_KEY_URL = process.env.GOERLI_API_KEY_URL;
const GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY;

const ETHERSCAN_KEY = process.env.ETHERSCAN_KEY;


const config: HardhatUserConfig = {
  solidity: {
    // 编译版本
    compilers: [
      {
        version: "0.8.14",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  defaultNetwork: "hardhat",
  networks: {
    goerli:{
      url: GOERLI_API_KEY_URL,
      accounts: [GOERLI_PRIVATE_KEY],
      chainId: 5
    },
  },
  gasReporter: {
    currency: 'CHF',
    gasPrice: 21,
    enabled: (process.env.REPORT_GAS) ? true : false
  },
 // skipFiles: ['contracts/XenAttackWithETH.sol']
};

export default config;
