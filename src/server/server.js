import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
require("@babel/polyfill");

let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let getAccounts = web3.eth.getAccounts();
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);

// flightSuretyApp.events.OracleRequest({
//     fromBlock: 0
//   }, function (error, event) {
//     if (error) console.log(error)
//     console.log(event)
// });

const app = express();

let statusCodes = [10,20,30,40,50];

//RegisterOracle
async function registerOracles(){
  let accounts = await getAccounts;
  let fee = await flightSuretyApp.methods.REGISTRATION_FEE().call();
  
  //Register one oracle with each account
  for(let a=0; a<accounts.length; a++) {   
    await flightSuretyApp.methods.registerOracle().send({ from: accounts[a], value: fee, gas: 3000000 });
    console.log("Oracle " +  a  + " Registered: " + accounts[a]); 
  }
};

async function submitOracleResponse(airline, flight, timestamp){
  let accounts = await getAccounts;
  let indexes = [];

  //For each Oracle Registered
  for(let a=0; a < accounts.length; a++) {  
    //get Random status code from list of possible values (statusCodes)
    let statusCode = statusCodes[Math.floor(Math.random() * (statusCodes.length - 0 + 1)) + 0];
    //Get indexes[3] for each Oracle (one registered for each account)
    let oracleIndexes = await flightSuretyApp.methods.getMyIndexes().call({from: accounts[a]});

    indexes[a] = oracleIndexes;

    console.log("loop " + a + " - oracleIndexes: " + oracleIndexes);

    for(let idx=0; idx < oracleIndexes.length; idx++){
      
      try {
        // Submit a response...it will only be accepted if there is an Index match
        await flightSuretyApp.methods
        .submitOracleResponse(oracleIndexes[idx], airline, flight, timestamp, statusCode)
        .send({from: accounts[a], gas: 3000000});
      }
      catch(e) {
        // Enable this when debugging
        //console.log('\nError', idx, oracleIndexes[idx], flight, timestamp);
        //console.log('\nError', e.data.reason);
      }
    }  
  };
};

// app.get('/api', (req, res) => {
//     res.send({
//       message: 'An API for use with your Dapp!'
//     })
// })

async function waitEvents() {
  //Called in App inside RegisterOracle
  // flightSuretyApp.events.OracleRegistered({}, (error, event) => {
  //   console.log("--------- OracleRegistered ---------");
  //   console.log(event.returnValues.indexes);
  // });

  //Called in App inside fetchFlightStatus
  flightSuretyApp.events.OracleRequest({}, async (error, event) => {
    if(error){
      console.log("Oracle Request Error", error);
    }
    else {
      console.log('------------------------------');
      console.log("Oracle Requested -> index: " + event.returnValues.index + 
                  "; flight: " + event.returnValues.flight + 
                  "; timestamp: " + event.returnValues.timestamp + 
                  "; key: " + event.returnValues.key);

      let index = event.returnValues.index;
      let airline = event.returnValues.airline;
      let flight = event.returnValues.flight;
      let timestamp = event.returnValues.timestamp;

      await submitOracleResponse(airline, flight, timestamp);   
    }
  });  

  flightSuretyApp.events.FlightStatusInfo({}, (error, event) => {
    console.log('------------------------------');
    console.log("FlightStatusInfo");
    console.log("flightKey :"+ event.returnValues.flight);
    console.log("StatusCode :"+ event.returnValues.status);
  });

  flightSuretyApp.events.FlightStatusProccessed({}, (error, event) => {
    console.log('------------------------------');
    console.log("FlightStatusProccessed");
    console.log("flightKey :"+ event.returnValues.flight);
    console.log("StatusCode :"+ event.returnValues.status);
  });

  flightSuretyData.events.FlightStatusUpdated({}, (error, event) => {
    console.log('------------------------------');
    console.log("FlightStatusUpdated");
    console.log(event.returnValues);
  });

  // flightSuretyApp.events.OracleReport({}, (error, event) => {
  //   console.log("/////////////// OracleReport //////////////");
  //   console.log(event.returnValues);
  // })
}

registerOracles();
waitEvents();

export default app;


