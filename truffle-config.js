module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",     
      port: 7545,            
      network_id: "*",       
    },
  },

  compilers: {
    solc: {
      version: "0.8.19", // Use the appropriate version for your contract
      settings: {
        optimizer: {
          enabled: true,
          runs: 200, // Adjust runs for optimization level
        },
      },
    },
  },
};