var HDWalletProvider = require("@truffle/hdwallet-provider");
var mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: () => new HDWalletProvider(mnemonic, 'https://mainnet.infura.io/v3/b3d19109d43642a5a916742f919c0081'),
        network_id: 4,      
        gasPrice: 9999999
    }
  },
  compilers: {
    solc: {
      version: "^0.4.24"
    }
  }
};