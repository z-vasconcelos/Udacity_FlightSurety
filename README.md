# FlightSurety

FlightSurety is a sample application project for Udacity's Blockchain course.

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`
`truffle compile`

## Develop Client

To run truffle tests:

`truffle test ./test/flightSurety.js`
`truffle test ./test/testFunctions.js`

For testing consensus you will need more than 50 airlines registered, use:
`ganache-cli --accounts=100`
than:
`truffle test ./test/airlineRubricTests.js`

For Oracles test we need 20 accounts for testing
`ganache-cli --accounts=21`
`truffle test ./test/oracles.js`

To use the dapp:

`truffle migrate`
`npm run dapp`

To view dapp:

`http://localhost:8000`

## Develop Server

`npm run server`
`truffle test ./test/oracles.js`

* To run servers, needed to install and import babel
install -> npm install --save @babel/polyfill
require -> require("@babel/polyfill");

## Deploy

To build dapp for prod:
`npm run dapp:prod`

Deploy the contents of the ./dapp folder


## Resources

* [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
* [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
* [Truffle Framework](http://truffleframework.com/)
* [Ganache Local Blockchain](http://truffleframework.com/ganache/)
* [Remix Solidity IDE](https://remix.ethereum.org/)
* [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
* [Ethereum Blockchain Explorer](https://etherscan.io/)
* [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)

#Call function
https://trufflesuite.com/docs/truffle/getting-started/interacting-with-your-contracts.html

let accounts = await web3.eth.getAccounts()
let instanceApp = await FlightSuretyApp.deployed()
let instanceData = await FlightSuretyData.deployed()

instanceApp.registerAirline(accounts[2], true)
instanceApp.getFlightKey(accounts[3], 'ND1309', 1640985006)
instanceApp.registerFlight(accounts[3], 'ND1309', 1640985006)

instanceApp.registerAirline(accounts[2], true)
instanceData.getFlightKey(accounts[3], 'ND1309', 1640985006)
instanceData.registerFlight(accounts[3], 'ND1309', 1640985006)

//require(flights[flyKey].isRegistered = true, "Flight already registered");

# Rubric Checklist 

## Airline

* Can be tested with `truffle test ./test/rubricAirline.js`
*   For this test will be necessary a high number of accounts in ganache
*   The tests were made using `ganache-cli --accounts=100` 

    OK - Airline Contract Initialization
        First airline is registered when contract is deployed.
    OK - Multiparty Consensus 
        Only existing airline may register a new airline until there are at least four airlines registered
        Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines
    OK - Airline Ante
        Airline can be registered, but does not participate in contract until it submits funding of 10 ether (make sure it is not 10 wei)

`truffle test ./test/rubricFlight.js`

## Passenger   
`truffle test ./test/flight.js`


