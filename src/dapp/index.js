
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let flightStatus = {
        0: "Status not available",
        10: "Flight in Time",
        20: "Flight Delay due to Airline",
        30: "Flight Delay due to Weather",
        40: "Flight Delay due to Technical Problems",
        50: "Flight Delay due to Other Issues"
    }

    //First Airline
    //let baseAirline;
    //For airline selected in flights droplist
    let selectedAirlineFlightsInfo = {};

    //store flights informations
    //Organized by Airlines
    let airlinesInfo = {};
    //Organized by Flights
    let fixedFlightList = [];
    //Organized by Departures
    let fixedDepartureList = [];
    //Organized by Arrivals
    let fixedArrivalList = [];

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });

        // contract.getAirlines((error, result) => {
        //     if(error){
        //         console.log(error);
        //     }
        //     //console.log(result);
        //     let baseAirline = result[0];         
        // });

        getFlightData();

        //Set firstAitline as Default to register flights
        DOM.elid('register-flight').value = contract.owner;     

        //User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('fetch-flight-number').value;
            let airline = DOM.elid('fetch-flight-airline').value;
            // Write transaction
            contract.fetchFlightStatus(airline, flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
                //console.log("fetchFlightStatus", result);
                location.reload();
            });
        })

        // Get Addresses
        DOM.elid('bt-get-addresses').addEventListener('click', () => {
            console.log(contract.getAccounts());
        })

        // Get Contract Balance
        DOM.elid('bt-get-contract-balance').addEventListener('click', () => {
            contract.getContractBalance((error, result) => {
                if(error){
                    console.log(error);
                }
                console.log(result);
            });
        })

        /********************************************************************************************/
        /*                                       AIRLINES                                           */
        /********************************************************************************************/

        // Register Airline
        DOM.elid('bt-register-airline').addEventListener('click', () => {
            let airlineToRegister = DOM.elid('register-airline').value;
            let airlineName = DOM.elid('airline-name').value;
            contract.registerAirline(airlineToRegister, airlineName, (error, result) => {
                display('Airline', 'Register Airline', [ { label: 'Register Airline', error: error, value: result} ]);
            });
        })

        //Get list of Airlines Names
        DOM.elid('bt-airline-menu').addEventListener('click', () => {
            contract.getAirlines((error, result) => {
                const div = document.querySelector('#dropdown-airlines');
                //clear div
                div.innerHTML = "";
                if(error){
                    console.log(error);
                }
                console.log(result);
                let airlines = result;

                airlines.forEach(el => {
                    div.innerHTML += `<a class="dropdown-item drop-airline-selector">${el}</a>`;            
                })
            });
        })

        let selectedAirlineAddress;
        //Get Clicked Airline Name
        $(document).on('click', '.airline-menu a', function(element) {
            let airlineName = element.currentTarget.innerHTML;

            console.log("airlineName:" + airlineName);

            contract.getAirlineByName(airlineName, (error, result) => {
                console.log("airlineAddress:" + result);
                selectedAirlineAddress = result;
            });

            const divFlights = document.querySelector('#bt-flight-menu');
            divFlights.disabled = false;

            //Set airlineName to the Droplist
            DOM.elid('bt-airline-menu').innerHTML = airlineName;
        }); 

        //Get Flights from dropList
        DOM.elid('bt-flight-menu').addEventListener('click', () => {

            let airlineName = selectedAirlineAddress;
            let flights = [];

            contract.getFlights(airlineName, (error, result) => {
                console.log(result);
                
                flights = result;
                let flighNames = flights.flightNames;
                let flighCodes = flights.flightCodes;

                const div = document.querySelector('#dropdown-flights');
                //clear div
                div.innerHTML = "";

                flighNames.forEach(el => {
                    //console.log(el);
                    div.innerHTML += `<a class="dropdown-item drop-flight-selector">${el}</a>`;
                });

                let id = 0;
                //Set itens into dictionary
                for(let i = 0; i < flighNames.length; i++){
                    selectedAirlineFlightsInfo[flighNames[i]] = {
                        "id": i,
                        "flightCode": flighCodes[i]
                    };
                };
            });
        })

        //Get Clicked Flight Name
        $(document).on('click', '.flight-menu a', function(element) {
            let flightName = element.currentTarget.innerHTML;

            //Set flightName to the Droplist
            DOM.elid('bt-flight-menu').innerHTML = flightName;

            let statusCode = fixedFlightList[flightName].statusCode;

            DOM.elid('flight-status').innerHTML = statusCode + " - " + flightStatus[statusCode];    

            // contract.getFlightStatus(flightKey, (error, result) => {
            //     console.log("getFlightStatus: ", result);
            //     DOM.elid('flight-status').innerHTML = result + " - " + flightStatus[result];
            // });
        });      

        //Get all Flights Data
        function getFlightData (){
            contract.getAirlines((error, airlineList) => {

                let flightInfo = {};

                airlineList.forEach(airline => {

                    airlinesInfo[airline] = {};
                    let airlineFlights = {};

                    contract.getAirlineByName(airline, (error, airlineAddress) => {

                        //console.log(airlineAddress);
                        contract.getFlights(airlineAddress, (error, flights) => {
                            
                            let flightNames = flights.flightNames;
                            let flighCodes = flights.flightCodes;

                            for(let i = 0; i < flighCodes.length; i++){
                                contract.getFlightsData(flighCodes[i], (error, flightData) => {

                                    //list of flight data organized by Airline
                                    airlineFlights[flightNames[i]] = flightData;
                                    fixedFlightList[flightNames[i]] = flightData;

                                    //list of flight data organized by Departure
                                    let departureInfo = [];
                                    departureInfo[flightData.departure] = flightData;
                                    if (fixedDepartureList[flightData.departure]) {
                                        fixedDepartureList[flightData.departure].push(departureInfo);
                                    } else {
                                        fixedDepartureList[flightData.departure] = [departureInfo];
                                    }

                                    //list of flight data organized by Arrival
                                    let arrivalInfo = [];
                                    arrivalInfo[flightData.arrival] = flightData;

                                    if (fixedArrivalList[flightData.arrival]) {
                                        fixedArrivalList[flightData.arrival].push(arrivalInfo);
                                    } else {
                                        fixedArrivalList[flightData.arrival] = [arrivalInfo];
                                    }
                                });
                            }; 
                        }); 
                    });    
                    airlinesInfo[airline] = airlineFlights;              
                });
                console.log("airlinesInfo: ", airlinesInfo);
                console.log("fixedFlightList: ", fixedFlightList);
                console.log("fixedDepartureList", fixedDepartureList);
                console.log("fixedArrivalList", fixedArrivalList);
            });
            
        }

        //Populate Fligth DropList Arrange by Available Flights
        DOM.elid('bt-flight-menuByName').addEventListener('click', () => {

            const div = document.querySelector('#dropdown-flight-menuByName');
            div.innerHTML = "";

            for (var f in fixedFlightList){
                //console.log(fixedFlightList[f][1]);
                div.innerHTML += `<a class="dropdown-item drop-flight-menuByName-selector">${fixedFlightList[f][1]}</a>`;
            }
        });

        //Get Status from flight name list
        $(document).on('click', '.flight-menuByName a', function(element) {
            let flightName = element.currentTarget.innerHTML;

            //Set flightName to the Droplist
            DOM.elid('bt-flight-menuByName').innerHTML = flightName;

            let statusCode = fixedFlightList[flightName].statusCode;

            DOM.elid('flight-status-af').innerHTML = statusCode + " - " + flightStatus[statusCode];        
        });

        //Populate Fligth DropList Arrange by Available Departures
        DOM.elid('bt-flight-menuByDeparture').addEventListener('click', () => {

            const div = document.querySelector('#dropdown-flight-menuByDeparture');
            div.innerHTML = "";

            for (var f in fixedDepartureList){
                div.innerHTML += `<a class="dropdown-item drop-flight-menuByName-selector">${fixedDepartureList[f][0][f][5]}</a>`;
            }
        });

        //Get Clicked Departure Name
        $(document).on('click', '.flight-menuByDeparture a', function(element) {
            let departure = element.currentTarget.innerHTML;

            const div = document.querySelector('#dropdown-flight-menuByDeparture-selectFlight');
            div.innerHTML = "";

            fixedDepartureList[departure].forEach(dep => {
                div.innerHTML += `<a class="dropdown-item drop-flight-menuByDeparture-selector">${dep[departure][1]}</a>`;
            });

            const divFlights = document.querySelector('#bt-flight-menuByDeparture-selectFlight');
            divFlights.disabled = false;           
        });

        //Get Status from flight name list
        $(document).on('click', '.flight-menuByDeparture-selectFlight a', function(element) {
            let flightName = element.currentTarget.innerHTML;

            //Set flightName to the Droplist
            DOM.elid('bt-flight-menuByDeparture-selectFlight').innerHTML = flightName;

            let statusCode = fixedFlightList[flightName].statusCode;

            DOM.elid('flight-status-ad').innerHTML = statusCode + " - " + flightStatus[statusCode];            
        });

        //Populate Fligth DropList Arrange by Available Arrival
        // DOM.elid('bt-flight-menuByArrival').addEventListener('click', () => {

        //     const div = document.querySelector('#dropdown-flight-menuByArrival');
        //     div.innerHTML = "";

        //     for (var f in fixedArrivalList){
        //         console.log(fixedArrivalList[f][0][f][6]);
        //         div.innerHTML += `<a class="dropdown-item drop-flight-menuByArrival-selector">${fixedArrivalList[f][0][f][6]}</a>`;
        //     }
        // });

        //Get Clicked Arrival Name
        // $(document).on('click', '.flight-menuByArrival a', function(element) {
        //     let departure = element.currentTarget.innerHTML;

        //     const div = document.querySelector('#dropdown-flight-menuByArrival-selectFlight');
        //     div.innerHTML = "";

        //     fixedDepartureList[departure].forEach(dep => {
        //         div.innerHTML += `<a class="dropdown-item drop-flight-menuByArrival-selector">${dep[departure][1]}</a>`;
        //     });

        //     const divFlights = document.querySelector('#bt-flight-menuByArrival-selectFlight');
        //     divFlights.disabled = false;           
        // });

        // Is Airline Registered?
        DOM.elid('bt-check-register-airline').addEventListener('click', () => {
            let airlineAddress = DOM.elid('check-register-airline').value;
            // Verify if airline is registered
            contract.isAirline(airlineAddress, (error, result) => {
                DOM.elid('isRegistered').innerHTML = result;
            });
        });

        ////////////////////////------ Vote ------////////////////////////
        DOM.elid('bt-voteIn-airline').addEventListener('click', () => {
            let airlineAddress = DOM.elid('voteIn-airline').value;
            // Register Airline
            contract.voteInAirline(airlineAddress, (error, result) => {
                display('Airline', 'Voting', [ { label: 'Vote in Airline', error: error, value: result.airlineToRegisterAddress} ]);
            });
            contract.voteInAirlineDebug(airlineAddress, (error, result) => {
                console.log(result);
            });
        });

        // Get Voters?
        DOM.elid('bt-get-vote-number').addEventListener('click', () => {
            let airlineAddress = DOM.elid('get-vote-number').value;
            // Verify if airline is registered
            contract.getVoters(airlineAddress, (error, result) => {
                console.log(result);
                //DOM.elid('isRegistered').innerHTML = result;
            });
        });

        // Get Amount of Votes?
        DOM.elid('bt-get-vote-number').addEventListener('click', () => {
            let airlineAddress = DOM.elid('get-vote-number').value;
            // Verify if airline is registered
            contract.getVoteAmount(airlineAddress, (error, result) => {
                DOM.elid('voteNumber').innerHTML = result;
            });
        });


        // Is Airline Validated?
        DOM.elid('bt-check-register-airline').addEventListener('click', () => {
            let airlineAddress = DOM.elid('check-register-airline').value;
            // Verify if airline is registered
            contract.isAirlineValid(airlineAddress, (error, result) => {
                //console.log("Is Airline Validated? -> " + result);
                DOM.elid('isValidated').innerHTML = result;
            });
        });

        // Is Airline Validated?
        DOM.elid('bt-check-register-airline').addEventListener('click', () => {
            let airlineAddress = DOM.elid('check-register-airline').value;
            // Verify if airline is registered
            contract.isAirlineValid(airlineAddress, (error, result) => {
                //console.log("Is Airline Validated? -> " + result);
                DOM.elid('isValidated').innerHTML = result;
            });
        });

        ////////////////////////------ Fund ------////////////////////////
        DOM.elid('bt-fund-airline').addEventListener('click', () => {
            // Register Airline
            let airlineAddress = DOM.elid('fund-airline').value;
            let fundValue = DOM.elid('fund-airline-value').value;
            contract.fundAirline(airlineAddress, fundValue, (error, result) => {
                display('Airline', 'Fund', [ { label: 'Fund Airline', error: error, value: result} ]);
            });
            contract.fundAirlineDebug(airlineAddress, fundValue, (error, result) => {
                console.log("Fund Result:");
                console.log(result);
                console.log("Fund Error:");
                console.log(error);
            });
        });

        // Is Airline Funded?
        DOM.elid('bt-check-register-airline').addEventListener('click', () => {
            let airlineAddress = DOM.elid('check-register-airline').value;
            // Verify if airline is registered
            contract.isAirlineFunded(airlineAddress, (error, result) => {
                //console.log("Is Airline Funded? -> " + result);
                DOM.elid('isFunded').innerHTML = result;
            });
        });

        /********************************************************************************************/
        /*                                       Flights                                           */
        /********************************************************************************************/

        //Register Flight
        DOM.elid('bt-register-flight').addEventListener('click', () => {
            let airlineAddress = DOM.elid('register-flight').value;
            let flightCode = DOM.elid('flight-code').value;
            let flightDeparture = DOM.elid('flight-departure').value;
            let flightArrival = DOM.elid('flight-arrival').value;
            let timesTamp = Math.floor(Date.now() / 1000)

            console.log(airlineAddress, flightCode, flightDeparture, flightArrival, timesTamp);

            contract.registerFlight(airlineAddress, flightCode, flightDeparture, flightArrival, (error, result) => {
                console.log(error);
                console.log(result);
                display('Flight', 'Register', [ { label: 'Register Flight', error: error, value: result} ]);
            });

            DOM.elid('fetch-flight-number').value = flightCode;
            DOM.elid('fetch-flight-airline').value = airlineAddress;
        });

        //Get Flights from Airline with AirlineAddress
        DOM.elid('bt-get-airline-flights').addEventListener('click', () => {
            let airlineAddress = DOM.elid('get-airline-flights').value;
            let airlineFlights = [];
            contract.getFlights(airlineAddress, (error, result) => {
                if(error){
                    console.log(error);
                } else {
                    airlineFlights = result;
                    console.log(airlineFlights);
                }
            });
        });

        ////////////////////////------ Helper ------////////////////////////
        DOM.elid('airline-mode').addEventListener('click', () => {
            let airlineSection = DOM.elid('airline-section');
            let passengerSection = DOM.elid('passenger-section');

            airlineSection.classList.remove('hidden');
            passengerSection.classList.add('hidden');
        });

        DOM.elid('passenger-mode').addEventListener('click', () => {
            let passengerSection = DOM.elid('passenger-section');
            let airlineSection = DOM.elid('airline-section');

            passengerSection.classList.remove('hidden');
            airlineSection.classList.add('hidden');
        });

        DOM.elid('debug-mode').addEventListener('click', () => {
            let debugEl = DOM.elid('debug-mode');
            let debugSection = DOM.elid('debug-section');
            //console.log(debugEl.checked);
            if(debugEl.checked){
                debugSection.classList.remove('hidden');
            } else {
                debugSection.classList.add('hidden');
            }
        });
    });    
})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({className:'row'}));
        row.appendChild(DOM.div({className: 'col-sm-4 field'}, result.label));
        row.appendChild(DOM.div({className: 'col-sm-8 field-value'}, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    });
    displayDiv.append(section);
};







