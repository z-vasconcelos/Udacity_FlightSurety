var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('airlineRubric', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    //await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/
  
  //Airline Contract Initialization -> First airline is registered when contract is deployed
  it(`Check if accounts[0] was registered while deploying contract`, async function () {
    // Get operating status
    let checkFirstAirlineRegister = await config.flightSuretyData.isAirlineRegistered(accounts[0]);
    assert.equal(checkFirstAirlineRegister, true, "There is no airline registered: " + checkFirstAirlineRegister);
  });

  //Only existing airline may register a new airline until there are at least FOUR airlines registered
  it(`Check if only existing airline may register a new airline until there are at least four airlines registered`, async function () {
    // Get operating status
    let firstAirline = accounts[0]; //fistAirline was registered while deploying
    let secondAirline = accounts[2];
    let tirdAirline = accounts[3];
    let fourthAirline = accounts[4];
    let nonAirlineAddress = accounts[5];
    let airlineToRegister = accounts[6];

    //A non existing airline trying to register an airline while there are less than four airlines registered
    try {
      await config.flightSuretyApp.registerAirline(airlineToRegister, "airlineToRegister",  {from: nonAirlineAddress});
    }
    catch(e) {
    }
    let whileLessThan4 = await config.flightSuretyApp.isAirlineRegistered.call(airlineToRegister);   
    
    //A non existing airline trying to register an airline while there are al last four airlines registered
    try {
      await config.flightSuretyApp.registerAirline(secondAirline, "secondAirline", {from: firstAirline});
      await config.flightSuretyApp.registerAirline(tirdAirline, "tirdAirline", {from: firstAirline});
      await config.flightSuretyApp.registerAirline(fourthAirline, "fourthAirline", {from: firstAirline});
      await config.flightSuretyApp.registerAirline(airlineToRegister, "airlineToRegister", {from: nonAirlineAddress});
    }
    catch(e) {
    }    
    let whileMoreThan4 = await config.flightSuretyApp.isAirlineRegistered.call(airlineToRegister);

    assert.equal(whileLessThan4, false, "A Non registered airline could not be able to register a new one after ther are at last 4 airlines registered");
    assert.equal(whileMoreThan4, true, "A Non registered airline should be able register a new one after ther are already 4 airlines registered");
  });

  //Airline Ante
  //Airline can be registered, but does not participate in contract until it submits funding of 10 ether (make sure it is not 10 wei)
  it(`Check if Airline can be registered, but can not participate in contract until it submits the necessary funding`, async function () {
    //Starting forward from the 10th account
    let firstAirline = accounts[0];
    let airlineToParticipate = accounts[90];
    let airlineToBeCalled = accounts[91];

    //Register airlines to be user for testing
    try {
      await config.flightSuretyApp.registerAirline(airlineToParticipate, "airlineToParticipate", {from: firstAirline});
      await config.flightSuretyApp.registerAirline(airlineToBeCalled, "airlineToBeCalled", {from: firstAirline});
    }
    catch(e) {
    }    

    //Trying to Participate voting
    // ACT
    try {
      await config.flightSuretyApp.vote.call(airlineToBeCalled, {from: airlineToParticipate});
    }
    catch(e) {
    }    

    let result = await config.flightSuretyApp.checkAirlineVote.call(airlineToBeCalled);
    assert.equal(result > 0, false, "Should not be able to participate without beying a Funded Airline");
  });

  //Multiparty Consensus -> Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines
  it(`Check for Multiparty Consensus`, async function () {
    //Starting forward from the 10th account
    let testRegisterinfFromAccountIndex = 10;
    let registerAmountToTest = 50 + testRegisterinfFromAccountIndex;
    let accountToTest = accounts[registerAmountToTest + 2];
    let index = 0;

    for (let i = testRegisterinfFromAccountIndex; i < registerAmountToTest; i++) {
      await config.flightSuretyApp.registerAirline(accounts[i], "airline" + i, {from: accounts[0]});
      index = i;
    }

    let result = await config.flightSuretyApp.isAirlineRegistered.call(accountToTest);
    assert.equal(result, false, "Should not register airline after the 50th without 50% consensus");
  });
});
