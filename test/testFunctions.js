var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('testFunctions', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    //await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/
  
  it(`Check if flightSuretyData contract is operational -> isOperational`, async function () {
    // Get operating status
    let operationalStatus = await config.flightSuretyData.isOperational.call();
    assert.equal(operationalStatus, true, "The Contract flightSuretyData is not operational. isOperational: " + operationalStatus);
  });

  it(`Check if there is any Airline Registered`, async function () {
    // Get operating status
    let airlines = accounts;
    assert.equal(airlines.length > 0, true, "There is no airline registered");
  });  

  it(`Fetch registered airlines`, async function () {

    let registerAirline = await config.flightSuretyApp.registerAirline.call(true, accounts[2]);
    assert.equal(registerAirline, (true, 0), "Fetch Airlines: " + config.flightSuretyData.airlines[accounts[2]]);
  });  

});
