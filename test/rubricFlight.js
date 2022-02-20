var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('flight', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    //await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/
  
  //GenerateFlightKey
  it(`Check if airline can register flight`, async function() {
    let airline = accounts[0];
    let flight = "123";
    let timestamp = Math.floor(Date.now() / 1000);

    try {
      await config.flightSuretyData.registerFlight(airline, flight, timestamp, 0);
    }
    catch(e) {
    }

    let resultRegister = await config.flightSuretyData.isFlightRegistered.call(airline, flight, timestamp);

    assert.equal(resultRegister, true, "Flight is not Registered");
  }); 
  
  //GenerateFlights
  it(`Check if can get flights`, async function() {
    let airline = accounts[0];
    let flight1 = "123";
    let flight2 = "234";
    let flight3 = "345";
    let timestamp = Math.floor(Date.now() / 1000);

    try {
      await config.flightSuretyData.registerFlight(airline, flight1, timestamp, 0);
      await config.flightSuretyData.registerFlight(airline, flight2, timestamp, 0);
      await config.flightSuretyData.registerFlight(airline, flight3, timestamp, 0);
    }
    catch(e) {
    }

    let result = await config.flightSuretyData.getFlights.call(airline);

    //Check if has 4 flights registered -> 3 from this test and one from the previous
    assert.equal(result.length == 4, true, "The amount of Flights registered differ from the tests: " + result.length + " Array result list: " + result);
  }); 


});
