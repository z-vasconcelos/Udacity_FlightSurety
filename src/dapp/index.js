
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async() => {

    let result = null;
    let userAddress;

    let contract = new Contract('localhost', () => {

        // Read transaction
        contract.isOperational((error, result) => {
            console.log(error,result);
            display('Operational Status', 'Check if contract is operational', [ { label: 'Operational Status', error: error, value: result} ]);
        });
    

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight = DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [ { label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + result.timestamp} ]);
            });
        })

        // Get Addresses
        DOM.elid('bt-get-addresses').addEventListener('click', () => {
            console.log(contract.getAccounts());
        })

        //----------- Airline
        // Register Airline
        DOM.elid('bt-register-airline').addEventListener('click', () => {
            let airlineToRegister = DOM.elid('register-airline').value;
            //console.log("Airline to register: " + airlineToRegister);
            // Register Airline
            contract.registerAirline(airlineToRegister, (error, result) => {
                //console.log(result);
                display('Airline', 'Register Airline', [ { label: 'Register Airline', error: error, value: result.airlineToRegisterAddress} ]);
            });
        })

        // Vote
        DOM.elid('bt-voteIn-airline').addEventListener('click', () => {
            let airlineAddress = DOM.elid('voteIn-airline').value;
            // Register Airline
            contract.voteInAirline(airlineAddress, (error, result) => {
                display('Airline', 'Voting', [ { label: 'Vote in Airline', error: error, value: result.airlineAddress} ]);
            });
            contract.voteInAirlineDebug(airlineAddress, (error, result) => {
                console.log(result);
            });
        })

        // Get Voters?
        DOM.elid('bt-check-register-airline').addEventListener('click', () => {
            let airlineAddress = DOM.elid('check-register-airline').value;
            // Verify if airline is registered
            contract.getVoters(airlineAddress, (error, result) => {
                console.log(result);
                //DOM.elid('isRegistered').innerHTML = result;
            });
        })

        // Fund
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
        })

        // Get Contract Balance
        DOM.elid('bt-get-contract-balance').addEventListener('click', () => {
            // Register Airline
            contract.getContractBalance((error, result) => {
                if(error){
                    console.log(error);
                }
                let amount = contract.web3.utils.fromWei(result, "ether");
                DOM.elid('contractBalance').innerHTML = amount + " ether";
            });
        })

        //Validations

        // Is Airline Registered?
        DOM.elid('bt-check-register-airline').addEventListener('click', () => {
            let airlineAddress = DOM.elid('check-register-airline').value;
            // Verify if airline is registered
            contract.isAirline(airlineAddress, (error, result) => {
                //console.log("Is Airline Registered? -> " + result);
                DOM.elid('isRegistered').innerHTML = result;
            });
        })

         // Is Airline Validated?
        DOM.elid('bt-check-register-airline').addEventListener('click', () => {
            let airlineAddress = DOM.elid('check-register-airline').value;
            // Verify if airline is registered
            contract.isAirlineValid(airlineAddress, (error, result) => {
                //console.log("Is Airline Validated? -> " + result);
                DOM.elid('isValidated').innerHTML = result;
            });
        })

        // Is Airline Funded?
        DOM.elid('bt-check-register-airline').addEventListener('click', () => {
            let airlineAddress = DOM.elid('check-register-airline').value;
            // Verify if airline is registered
            contract.isAirlineFunded(airlineAddress, (error, result) => {
                //console.log("Is Airline Funded? -> " + result);
                DOM.elid('isFunded').innerHTML = result;
            });
        })

        // Get Amount of Votes?
        DOM.elid('bt-get-vote-number').addEventListener('click', () => {
            let airlineAddress = DOM.elid('get-vote-number').value;
            // Verify if airline is registered
            contract.getVoteAmount(airlineAddress, (error, result) => {
                DOM.elid('voteNumber').innerHTML = result;
            });
        })

        //-------------------------- Helper
        DOM.elid('airline-mode').addEventListener('click', () => {
            let airlineSection = DOM.elid('airline-section');
            let passengerSection = DOM.elid('passenger-section');

            airlineSection.classList.remove('hidden');
            passengerSection.classList.add('hidden');
        })

        DOM.elid('passenger-mode').addEventListener('click', () => {
            let passengerSection = DOM.elid('passenger-section');
            let airlineSection = DOM.elid('airline-section');

            passengerSection.classList.remove('hidden');
            airlineSection.classList.add('hidden');
        })

        DOM.elid('debug-mode').addEventListener('click', () => {
            let debugEl = DOM.elid('debug-mode');
            let debugSection = DOM.elid('debug-section');
            //console.log(debugEl.checked);
            if(debugEl.checked){
                debugSection.classList.remove('hidden');
            } else {
                debugSection.classList.add('hidden');
            }
        })
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
    })
    displayDiv.append(section);

}







