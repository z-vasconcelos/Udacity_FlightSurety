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

# Rubric Checklist 

## Airline

* Can be tested with `truffle test ./test/rubricAirline.js`
*   For this test will be necessary a high number of accounts in ganache
*   The tests were made using `ganache-cli --accounts=100` 

    OK - Airline Contract Initialization<br />
        First airline is registered when contract is deployed.<br /><br />
    OK - Multiparty Consensus<br />
        Only existing airline may register a new airline until there are at least four airlines registered<br />
        Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines<br /><br />
    OK - Airline Ante<br />
        Airline can be registered, but does not participate in contract until it submits funding of 10 ether (make sure it is not 10 wei)<br />

## Passenger   
* Can be partially tested with `truffle test ./test/rubricPassenger.js`

    OK - Passenger Payment<br />
    Passengers may pay up to 1 ether for purchasing flight insurance.<br /><br />
    OK - Passenger Repayment<br />
    If flight is delayed due to airline fault, passenger receives credit of 1.5X the amount they paid<br />

* Needs to be tested a functional test running the dapp
    
    OK - Passenger Withdraw<br />
    Passenger can withdraw any funds owed to them as a result of receiving credit for insurance payout<br /><br />
    Review (I am not sure if I got what had to be done here) - Insurance Payouts<br />
    Insurance payouts are not sent directly to passenger’s wallet<br />

# To call functions using truffle console, first set:
    let accounts = await web3.eth.getAccounts()
    let instanceApp = await FlightSuretyApp.deployed()
    let instanceData = await FlightSuretyData.deployed()

# Dapp utilization

To simulate a minimal dapp to the airline proccess. Select the "Airline Mode" in the Dapp

    Airline Options:
    - Register Airline
    - Vote in Airline
    - Fund Airline
    - Register Flight
    - Fetch Flight / Proccess Flight Status

![Alt text](img/airline.png?raw=true "Airline Options")

To simulate a minimal dapp to the passenger proccess. Select the "Passenger Mode" in the Dapp

    Passenger/Insuree Options:
    - Check Available Insurances
    - Buy Insurance
    - Redeem Insurance (as credit)
    - Check Available Credits
    - Withdraw Credits

![Alt text](img/passenger.png?raw=true "Passenger Options")

* !Important Notes:
Airline Registration
- The debug mode has a verifier if airline registration status. It needs 4 votes to be aproved in votation and then to be funded.
- The firstAirline has no initial fund. So to test an insurance buy, or it will be need to fund the firstAirline (accounts[0]) or an airline will need to be registered, voted and and funded, because to buy an insurance from an airline, the contract check if the airline has enought funs to conver the insurance value.

Flight Registration and Insurance Aquisition
- After an airline register a flight, the same airline needs to submit to Oracles to Proccess de Flight Status
- If the Flight Status is proccessed (different from 0), it will no more be available for insurance purchase
- To test the procces to credit a passenger/insuree, a flight will need to be registered -> the passenger then will be able to buy an insurance -> then the flight needs to be proccessed -> The insuree will be credited when he consults his flight to check if can be insured (this were made to avoid a for loop in the contract to credit the buyers. The intention is to work as a redeen procces triggered by the user) -> The insuree will be credited only if the flight status is equal to 20





