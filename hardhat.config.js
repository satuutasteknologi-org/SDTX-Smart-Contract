import * as dotenv from "dotenv";
dotenv.config();

import hardhatVerify from "@nomicfoundation/hardhat-verify";

/** @type import('hardhat/config').HardhatUserConfig */
export default {
  plugins: [hardhatVerify],
  solidity: {
    version: "0.8.34",
    settings: {
      evmVersion: "cancun",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    base: {
      type: "http",
      url: process.env.BASE_MAINNET_RPC || "https://mainnet.base.org",
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      base: "D17FUP5F3PCK6SDDIXV46HDJPUSAAEGXFW"
    }
  }
};
