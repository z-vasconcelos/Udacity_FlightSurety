// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    
    FlightSuretyData flightSuretyData; // Instance FlightSuretyData

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    //Airline Business Rules
    uint256  public constant AIRLINE_REGISTRATION_FEE = 10 ether;
    uint256  AIRLINE_AMOUNT_FOR_CONSENSUS = 50;

    //Votes Business Rules
    uint256  private VOTES_MIN_FOR_REGISTRATION = 4;

    //Passenger Rules
    uint256  private constant INSURANCE_MAX_VALUE = 1 ether;

    //use to set dataContract inside constructor
    address payable dataContractAddress;

    address payable contractOwner;          // Account used to deploy contract
    bool private operational = true;        // Blocks all state changes throughout the contract if fals

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event MinVotesForAirlineRegisterUpdated (uint8 numberOfVotesRequested);

    event OracleRegistered(address oracle);
    event FlightStatusProccessed(address airline, string flight, uint256 timestamp, uint8 status);

    event InsuranceAquired1 (bytes32 flightKey, address buyerAddress, uint256 insuranceValue);
 
    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
         // Modify to call data contract's status
        require(operational, "Contract is currently not Operational");  
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not Contract Owner");
        _;
    }

    //Modifier that requires the caller to be a Registered airline
    modifier requireIsAirlineRegistered()
    {
        require(flightSuretyData.isAirlineRegistered(msg.sender), "Caller is not a Registered Airline");  
        _;
    }

    //Modifier that requires the caller to be a Valid (has received the minimun amount of votes for activation) airline
    modifier requireIsAirlineValid()
    {
        require(flightSuretyData.isAirlineValid(msg.sender), "Airline has not received the amount necessary of votes and is not a valid one");  
        _;
    }

    //Modifier that requires the caller to be a Funded airline
    modifier requireIsAirlineFunded()
    {        
        require(flightSuretyData.isAirlineFunded(msg.sender), "Caller is not a Funded Airline");  
        _; 
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address payable dataContract
                                ) 
                                public
                                payable
    {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);

        dataContractAddress = dataContract;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational()   
                            requireContractOwner
                            public
                            view
                            returns(bool) 
    {
        return operational;  // Modify to call data contract's status
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    //1 - Passengers may pay up to 1 ether for purchasing flight insurance.
    function buyInsurance
                        (
                            bytes32 flightKey
                        )
                        requireIsOperational
                        public
                        payable
    {
        require(!flightSuretyData.isAirlineRegistered(msg.sender), "An Airline can not be insured for its own Flights");
        //Check value
        //Passengers may pay up to 1 ether for purchasing flight insurance.
        uint256 insuranceValue = msg.value;
        require(insuranceValue <= INSURANCE_MAX_VALUE, "The max insurance amount allowed is 1 ether");

        //--check if airline funnds can cover the purchase
        //get airline funds
        address airlineAddress = flightSuretyData.getFlightAirline(flightKey);
        uint256 insuranceAirlineFunds = flightSuretyData.getAirlineFund(airlineAddress);

        require(insuranceAirlineFunds >= insuranceValue, "The Airline is with pending information for this flight. For your protection, this transaction is not possible now");
        //--check if airline funds can cover the purchase

        emit InsuranceAquired1(flightKey, msg.sender, insuranceValue);

        flightSuretyData.buy(flightKey, msg.sender, insuranceValue);

        payable(address(dataContractAddress)).transfer(insuranceValue);
    }

    //2 - If flight is delayed due to airline fault, passenger receives credit of 1.5X the amount they paid.
    function calculateInsurance
                                (
                                    uint256 insuranceValue
                                )
                                internal
                                pure
                                returns(uint256 amounsToCover)
    {
        uint256 amountToCredit = insuranceValue + (insuranceValue * 50 / 100);
        return(amountToCredit);
    }

    function creditInsuree
                                (
                                    bytes32 delayedFlight,
                                    address insuree
                                )
                                requireIsOperational
                                public
    {
        //confirm flight status
        require(flightSuretyData.getFlightStatus(delayedFlight) == 20, "This flight status is not covered by the insurance");
        
        //call service to check insurance value and amount to credit
        uint256 insuranceValue = flightSuretyData.getInsuranceValue(delayedFlight, insuree);
        uint256 amountToCredit = calculateInsurance(insuranceValue);

        //credit insurance
        flightSuretyData.creditInsuree(insuree, delayedFlight, amountToCredit);
    }

    function getInsuranceData(
                                bytes32 insuranceKey
                            )
                            public
                            view
    {
        flightSuretyData.getInsuranceData(insuranceKey);
    }

    function payInsuree
                        (
                            uint256 amountToWithdraw
                        )
                        requireIsOperational
                        public
    {
        uint256 insureeCredits = flightSuretyData.getInsureeCredits(msg.sender);
        require(amountToWithdraw > 0, "Please insert a value greater than 0 to a withdraw request");
        require(insureeCredits >= amountToWithdraw, "You do not have enough credit for this transaction");
    
        flightSuretyData.pay(msg.sender, amountToWithdraw);
    }

    function getInsureeAvailableCredits
                                        (
                                        )
                                        public
                                        view
                                        returns(uint256 insureeCredits)
    {
        return(flightSuretyData.getInsureeCredits(msg.sender));
    }
  
   /**
    * @dev Add an airline to the registration queue
    *
    */   

    //write
    function registerAirline
                            (
                                address airlineToRegisterAddress,
                                string memory airlineName
                            )
                            requireIsOperational
                            public
    {
        require(!flightSuretyData.isAirlineRegistered(airlineToRegisterAddress), "Airline is already registered.");

        uint256 numberOfRegisteredAirlines = flightSuretyData.getAmountOfAirlinesRegistered();

        //Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines
        if (numberOfRegisteredAirlines >= AIRLINE_AMOUNT_FOR_CONSENSUS){
            //Put Airline in Pending Register to wait for votes to be registered
            flightSuretyData.setAirlinePendingRegister(airlineToRegisterAddress, airlineName);
        }else {
            //Only existing airline may register a new airline until there are at least FOUR airlines registered
            if(numberOfRegisteredAirlines <= 2){
                require(flightSuretyData.isAirlineRegistered(msg.sender), "Caller is not a registered airline. Minimun amount airlines not achieved for non registered airline be able to register new ones");
                flightSuretyData.registerAirline(airlineToRegisterAddress, airlineName);
            } else {
                flightSuretyData.registerAirline(airlineToRegisterAddress, airlineName);
            }
        }
        
    }

    //read
    function isAirlineRegistered(address airlineAddress) external returns(bool) {
        return(flightSuretyData.isAirlineRegistered(airlineAddress));
    }

    //write
   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight
                                (      
                                    address airlineAddress,
                                    string calldata flightName,
                                    string memory from,
                                    string memory to,
                                    uint256 timestamp
                                )
                                requireIsOperational
                                requireIsAirlineFunded
                                public
    {   
        uint8 flightStatus = STATUS_CODE_UNKNOWN;
        flightSuretyData.registerFlight(airlineAddress, flightName, from, to, timestamp, flightStatus);
    }

    function getFlightsFromAirline
                                (
                                    address airlineAddress
                                )
                                public
                                returns(string[] memory flightNames, bytes32[] memory flightCodes)
    {
        return(flightSuretyData.getFlights(airlineAddress));
    }
    
    function getFlightStatus
                            (
                                bytes32 flightCode
                            )
                            public
                            view
                            returns(uint8)
    {
        return(flightSuretyData.getFlightStatus(flightCode));
    }

   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string calldata flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                requireIsOperational
                                public
    {
        emit FlightStatusProccessed(airline, flight, timestamp, statusCode);
        flightSuretyData._processFlightStatus(airline, flight, statusCode);
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string calldata flight,
                            uint256 timestamp                            
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp, key);
    } 

    function fund
                (
                )
                public
                payable
                requireIsOperational
                requireIsAirlineRegistered
                requireIsAirlineValid
    {
        //Check Fund value
        require(msg.value >= AIRLINE_REGISTRATION_FEE, "Minimum funding is at last 10 Ether");

        flightSuretyData.fund(msg.sender, msg.value);

        payable(address(dataContractAddress)).transfer(msg.value);
    }

    function vote
                (
                    address airlineToVoteAddress
                )
                requireIsOperational
                requireIsAirlineRegistered
                requireIsAirlineValid
                requireIsAirlineFunded
                public
    {
        require(flightSuretyData.isAirlineRegistered(airlineToVoteAddress), "You can not vote in a airline that is not registered");

        bool voteValidationStatus;        
        uint256 numberOfRegisteredAirlines = flightSuretyData.getAmountOfAirlinesRegistered();
        uint256 voteAmount = flightSuretyData.getVoteAmount(airlineToVoteAddress);
        
        //#Airlines 03
        //Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines
        
        //check if current number of registered airlines is less than 50
        if(numberOfRegisteredAirlines < AIRLINE_AMOUNT_FOR_CONSENSUS){
            //If it is less, check if airline has more than 4 votes to be validated
            if((voteAmount + 1) >= VOTES_MIN_FOR_REGISTRATION){
                voteValidationStatus = true;
            } else {
                voteValidationStatus = false;
            }
        } else {
            //If it is more or equal 50, check if airline has votes from more than 50% of the registered airlines to be validated
            if(voteAmount > (numberOfRegisteredAirlines/2)){
                voteValidationStatus = true;
                flightSuretyData.setAirlineOutPendingRegister(airlineToVoteAddress);
            } else {
                voteValidationStatus = false;
            }        
        }

        //Vote. The vote validation is updated above
        flightSuretyData.vote(airlineToVoteAddress, msg.sender, voteValidationStatus);   
    }

    function checkAirlineVote
                            (
                                address airlineAddress
                            )
                            public
                            returns(bool status, uint256 numVotes)
    {
        return(flightSuretyData.checkAirlineVote(airlineAddress));
    }

// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp, bytes32 key);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
                            requireIsOperational
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });

        emit OracleRegistered(msg.sender);
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3] memory)
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string calldata flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");

        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);
            //emit FlightStatusProccessed(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3] memory)
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}

abstract contract FlightSuretyData {
    //requirements
    function isAirlineRegistered(address airlineAddress) virtual external returns(bool);
    function isAirlineValid(address airlineAddress) virtual external returns(bool);
    function isAirlineFunded(address airlineAddress) virtual external returns(bool);
    //airline register
    function registerAirline(address airlineAddress, string memory airlineName) virtual external;
    function getAmountOfAirlinesRegistered() virtual public view returns(uint256);
    function setAirlinePendingRegister(address airlineAddress, string memory airlineName) virtual external;
    function setAirlineOutPendingRegister(address airlineAddress) virtual external;
    //airline fund
    function fund(address airlineAddress, uint fundValue) virtual external;
    function registerFundValidation(uint8 rKey, address caller) virtual external;  
    //airline vote
    function isAprovedInVotation(address airlineAddress) virtual external view returns(bool);
    function vote(address airlineToVoteAddress, address voter, bool voteValidationStatus) virtual external;
    function checkAirlineVote(address airlineAddress) virtual external returns(bool status, uint256 numVotes)   ;
    function getVoteAmount(address airlineAddress) virtual public view returns(uint256);
    //flight
    function registerFlight(address airlineAddress, string calldata flightName, string memory from, string memory to, uint256 timestamp, uint8 flightStatus) virtual external;
    function _processFlightStatus(address airline, string calldata flight, uint8 statusCode) virtual external;
    function getFlights(address airlineAddress) virtual public returns(string[] memory flightNames, bytes32[] memory flightCodes);
    function getFlightStatus(bytes32 flightCode) virtual public view returns(uint8 flightStatusCode);
    function getFlightsData(bytes32 flightKey) virtual public view returns(
                                                                                string memory flightCode,        
                                                                                uint8 statusCode,
                                                                                uint256 timesTamp,      
                                                                                address airline,
                                                                                string memory departure,
                                                                                string memory arrival,
                                                                                bytes32 flight
                                                                            );
    function getFlightAirline(bytes32 flightKey) virtual public view returns(address);
    function getAirlineFund(address airlineAddress) virtual external view returns(uint256);
    //passenger
    function buy (bytes32 flightKey, address buyerAddress, uint256 insuranceValue) virtual external payable returns(address userAddress, bytes32[] memory insurances);
    function getInsuranceValue (bytes32 flightKey, address insuranceOwner) virtual external view returns(uint256 insuranceValue);
    function creditInsuree (address insuree, bytes32 flightKey, uint256 amountToCredit) virtual external payable;
    function pay (address insuree, uint256 amountToPay) virtual external payable;
    function getInsureeCredits (address insureeAddress) virtual external view returns(uint256 insureeCredits);
    function getInsuranceData (bytes32 insuranceKey) virtual public view returns(bool insuranceStatus, bytes32 flightKey, uint256 flightValue, address passengerAddress);
}  
    

    
