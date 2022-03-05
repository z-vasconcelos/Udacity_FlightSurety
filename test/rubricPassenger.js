var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('PassengerRubric', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    //await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`Check if Passengers may pay up to 1 ether for purchasing flight insurance`, async function() {
    let airline = accounts[0];
    let flight = "I89HGI";
    let timestamp = Math.floor(Date.now() / 1000);
    let passenger = accounts[1];
    let flighKey = await config.flightSuretyData.getFlightKey(airline, flight, timestamp);
    let buyInsurance;
    //let tryToByExcedingLimit;

    //register a flight
    await config.flightSuretyData.registerFlight(airline, flight, "MG", "SP", timestamp, 0);

    try {      
      buyInsurance = await config.flightSuretyData.buy(flighKey, passenger, "500000000000000000");
    }
    catch(e) {
    }

    let checkBuyInsuranceValue = await config.flightSuretyData.getInsuranceValue.call(flighKey, passenger);

    assert.equal(checkBuyInsuranceValue ==  "500000000000000000", true, "The insurance was not aquired. Should be 0,5 ether. Value returned: " + checkBuyInsuranceValue);
  }); 

  it(`Check if when flight is delayed due to airline fault, passenger receives credit of 1.5X the amount they paid`, async function() {
    let airline = accounts[0];
    let flightOk = "L38UIH";
    let flightNotOk = "0POI98H";
    let timestamp = Math.floor(Date.now() / 1000);
    let passenger = accounts[3];
    let OkflighKey = await config.flightSuretyData.getFlightKey(airline, flightOk, timestamp);
    let NotOkflighKey = await config.flightSuretyData.getFlightKey(airline, flightNotOk, timestamp);
    let passengerCredits;
    let insuranceValue = 4;
    let checkInsuranceValue;

    //register flight with an flight status => 0
    await config.flightSuretyData.registerFlight(airline, flightOk, "MG", "SP", timestamp, 0);
    //buy this flight to put $ in contract (there is no fund yet)
    await config.flightSuretyData.buy(OkflighKey, passenger, insuranceValue.toString());

    //register flight with an flight status => 20
    await config.flightSuretyData.registerFlight(airline, flightNotOk, "MG", "SP", timestamp, 0);
    //buy 1 ether insurance of the insurance thar will generate credit
    await config.flightSuretyData.buy(NotOkflighKey, passenger, insuranceValue.toString());

    checkInsuranceValue = await config.flightSuretyData.getInsuranceValue(NotOkflighKey, passenger);

    //Proccess flight status
    await config.flightSuretyData._processFlightStatus(airline, flightNotOk, 20);

    let x = new BigNumber(insuranceValue);
    let amountToCredit = x.multipliedBy(1.5);

    await config.flightSuretyData.creditInsuree(passenger, NotOkflighKey, amountToCredit.toString());

    //check credits
    try {
      passengerCredits = await config.flightSuretyData.getInsureeCredits(passenger);
    }
    catch(e) {
    }

    assert.equal(passengerCredits == 6, true, "The credit was not apliyed as it should (1,5X the value Insured). Were insured 1 ether, the credit available is: " + passengerCredits + ". The insurance value is: " + checkInsuranceValue);
  }); 
});
