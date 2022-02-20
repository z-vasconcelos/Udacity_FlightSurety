import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import flightSuretyData from '../../build/contracts/flightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.flightSuretyData = new this.web3.eth.Contract(flightSuretyData.abi, config.dataAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.accounts = []
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
            this.owner = accts[0];

            let counter = 1;
            
            while(this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while(this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            this.accounts = accts;

            callback();
        });
    }

    isOperational(callback) {
       let self = this;
       self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner}, callback);
    }

    getAccounts(){
        return(this.accounts);
    }

    /********************************************************************************************/
    /*                                       AIRLINES                                           */
    /********************************************************************************************/
    registerAirline(airlineToRegister, nameOfAirline, callback) {
        let self = this;
        let payload = {
            airlineToRegisterAddress: airlineToRegister,
            airlineName: nameOfAirline
        } 
        self.flightSuretyApp.methods
            .registerAirline(payload.airlineToRegisterAddress, payload.airlineName.toString())
            .send({from: self.owner, gas: 3000000}, (error, result) => {
                callback(error, result);
            });
    }

    //Get all airlines
    getAirlines(callback){
        let self = this;
        self.flightSuretyData.methods
        .getAirlines()
        .call({from: self.owner}, callback);
    }

    //Airline Validation
    isAirline(airlineToCheck, callback) {
        let self = this;
        self.flightSuretyData.methods
            .isAirline(airlineToCheck)
            .call({ from: self.owner}, callback);
    }

    isAirlineValid(airlineToCheck, callback) {
        let self = this;
        self.flightSuretyData.methods
            .isAirlineValid(airlineToCheck)
            .call({ from: self.owner}, callback);
    }

    isAirlineFunded(airlineToCheck, callback) {
        let self = this;
        self.flightSuretyData.methods
            .isAirlineFunded(airlineToCheck)
            .call({ from: self.owner}, callback);
    }

    getAirlineByName(name, callback) {
        let self = this;
        let payload = {
            airlineName: name
        } 
        self.flightSuretyData.methods
            .getAirlineByName(payload.airlineName)
            .call({ from: self.owner}, callback);
    }

    ////////////////////////------ Vote ------////////////////////////
    voteInAirline(airlineToRegister, callback) {
        let self = this;
        let payload = {
            airlineToRegisterAddress: airlineToRegister
        } 
        self.flightSuretyApp.methods
            .vote(payload.airlineToRegisterAddress)
            .send({from: self.owner, gas: 3000000}, (error, result) => {
                callback(error, payload);
            });
        //other owner to send in From -> this.accounts[8]
    }

    voteInAirlineDebug(airlineToRegister, callback) {
        let self = this;
        let payload = {
            airlineToRegisterAddress: airlineToRegister
        } 
        self.flightSuretyApp.methods
            .vote(payload.airlineToRegisterAddress)
            .call({ from: self.owner}, (error, result) => {
                callback(error, result);
            });
        //other owner to send in From -> this.accounts[8]
    }

    getVoters(airlineAddress, callback) {
        let self = this;
        let payload = {
            airlineToRegisterAddress: airlineAddress
        } 
        self.flightSuretyData.methods
            .getVoters(payload.airlineToRegisterAddress)
            .call({ from: self.owner}, (error, result) => {
                callback(error, result);
            });
        //other owner to send in From -> this.accounts[8]
    }

    getVoteAmount(airlineToCheck, callback) {
        let self = this;
        self.flightSuretyData.methods
            .getVoteAmount(airlineToCheck)
            .call({ from: self.owner}, callback);
    }

    ////////////////////////------ Fund ------////////////////////////
    fundAirline(airlineAddress, fundValue, callback) {
        let self = this;
        let payload = {
            airlineToFund: airlineAddress,
            fund: fundValue
        }
        self.flightSuretyApp.methods
            .fund()
            .send({from: payload.airlineToFund, value: self.web3.utils.toWei(payload.fund.toString(), "ether"), gas: 3000000}, (error, result) => {
                callback(error, result);
            });
        //other owner to send in From -> this.accounts[8]
    }

    //Fund Debug
    fundAirlineDebug(airlineAddress, fundValue, callback) {
        let self = this;
        let payload = {
            airlineToFund: airlineAddress,
            fund: fundValue
        }
        self.flightSuretyApp.methods
            .fund()
            .call({from: payload.airlineToFund, value: self.web3.utils.toWei(payload.fund.toString(), 'ether')}, (error, result) => {
                callback(error, result);
            });
        //other owner to send in From -> this.accounts[8]
    }

    getContractBalance(callback) {
        let self = this;
        self.flightSuretyData.methods
            .getContractBalance()
            .call({from: self.owner}, callback);
    }

    ////////////////////////------ Flights ------////////////////////////
    
    //Register a Flight
    registerFlight(airlineAddress, flightCode, departure, arrival, callback){
        let self = this;
        let payload = {
            airline: airlineAddress,
            flight: flightCode,
            from: departure,
            to: arrival,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .registerFlight(payload.airline, payload.flight, payload.from, payload.to, payload.timestamp)
            .send({from: self.owner, gas: 3000000}, (error, result) => {
                callback(error, result);
            });
    }

    //Get Flights from Airline with AirlineAddress
    getFlights(airlineAddress, callback){
        let self = this;
        let payload = {
            airline: airlineAddress
        }
        self.flightSuretyData.methods
            .getFlights(payload.airline)
            .call({from: self.owner}, callback);
    }

    getFlightsData(flightCode, callback){
        let self = this;
        let payload = {
            flightKey: flightCode
        }
        self.flightSuretyData.methods
            .getFlightsData(payload.flightKey)
            .call({from: self.owner}, callback);
    }

    getFlightStatus(flightCode, callback){
        let self = this;
        let payload = {
            flightKey: flightCode
        }
        self.flightSuretyApp.methods
            .getFlightStatus(payload.flightKey)
            .call({from: self.owner}, callback);
    }

    fetchFlightStatus(airlineAddress, flightName, callback){
        let self = this;
        let payload = {
            airline: airlineAddress,
            flight: flightName,
            timestamp: Math.floor(Date.now() / 1000)
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({from: self.owner}, (error, result) => {
                callback(error, payload);
            });
    }
}