import * as dotenv from 'dotenv'

import { HardhatUserConfig, task } from 'hardhat/config'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
import '@openzeppelin/hardhat-upgrades'
import '@typechain/hardhat'
import 'hardhat-gas-reporter'
import 'hardhat-deploy'
import 'solidity-coverage'

dotenv.config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545',
    },
    hardhat: {},
    polygon: {
      url: 'https://matic-mainnet.chainstacklabs.com/',
      gas: 8000000,
      chainId: 137,
      accounts: process.env.Memonic !== undefined ? [process.env.Memonic] : [],
    },
    mumbai: {
      url: 'https://matic-mumbai.chainstacklabs.com',
      gas: 8000000,
      chainId: 80001,
      accounts: process.env.Memonic !== undefined ? [process.env.Memonic] : [],
    },
    avaxfuji: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      chainId: 43113,
      gas: 8000000,
      gasPrice: 26000000000,
      accounts: process.env.Memonic !== undefined ? [process.env.Memonic] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },
  etherscan: {
    apiKey: {
      avalancheFujiTestnet: 'WN8CWW97AHIYUBC665Y4HZ4E5V4GUJZR2Y',
      polygon: 'UAPMUQ8M3UDIFBIUUZJC6ZYDPYW3D4GTPK',
      polygonMumbai: 'UAPMUQ8M3UDIFBIUUZJC6ZYDPYW3D4GTPK',
    },
  },
  paths: {
    artifacts: './artifacts',
    cache: './cache',
    sources: './contracts',
    tests: './test',
  },
  solidity: {
    compilers: [
      {
        version: '0.8.14',
      },
      {
        version: '0.6.12',
      },
      {
        version: '0.6.6',
      },
    ],
    overrides: {
      'contracts/Tomb.sol': {
        version: '0.6.12',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/TBond.sol': {
        version: '0.6.12',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/MaticWETH.sol': {
        version: '0.8.14',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/Luchador.sol': {
        version: '0.8.14',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/Trainer.sol': {
        version: '0.8.14',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/interface/ITrainer.sol': {
        version: '0.8.14',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/interface/Battle.sol': {
        version: '0.8.14',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
    },
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
}

export default config
