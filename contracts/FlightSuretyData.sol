// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    //add the keyword payable to the state variable
    address public contractOwner;         // Account used to deploy contract
    bool private operational = true;       // Blocks all state changes throughout the contract if false

    struct Insurance {
        bool isActive;
        bool isCredited;
        bool possibleFraud;
        bytes32 flight;
        uint256 value;
        address passenger;
    }
    mapping(bytes32 => Insurance) private insurances;

    struct Passenger {
        uint256 fund;
        uint256 credits;
        bytes32[] flightInsurances;
    } 
    mapping(address => Passenger) private passengers;

    struct Flight {
        bool isRegistered;
        string flightCode;        
        uint8 statusCode;
        uint256 timestamp;        
        address airline;
        string departure;
        string arrival;
    }
    mapping(bytes32 => Flight) private flights;

    struct Airline {
        bool pendingRegister;
        bool isRegistered;
        bool isValid;      //true if airline received minimum vote amount for validation
        bool isActive;     //true if airline is currenctly ative/flying
        bool isFunded;     //true if airline has received the fund registrationFee
        uint256 fund;
        string airlineName;
    }
    mapping(address => Airline) private airlines;

    string[] private airlinesNames;

    struct AirlineByName {
        address airlineAddr;
    }
    mapping(string => AirlineByName) private airlinesByName;

    struct AirlineFlight {
        bytes32[] flightCode;
        string[] flightName;
    }
    mapping(address => AirlineFlight) airlineFlights;

    struct FlightByName {
        bytes32 flightKey;
    }
    mapping(string => FlightByName) private flightsByName;

    struct Vote {
        uint256 voteNumber;
        mapping(address => bool) votedBy;
    }
    mapping(address => Vote) public votes;

    struct ValidateFund {
        uint8 key;
        bool isVerified;
    }
    mapping(address => ValidateFund) private fundsValidation;

    uint256 private numberOfairlinesRegistered = 0;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event FirstAirlineRegistered (address indexed account, bool registrationStatus);
    event AirlineRegistered (address indexed account);
    event AirlineFunded (address indexed account);
    event VotedInAirline (address indexed account);
    event AirlineFunded(address airlineAddress, string airlineName, uint256 fundValue);

    event FlightRegistered (bytes32 flightKey, address indexed account);
    event FlightStatusUpdated (uint8 statusCode, string flightCode);

    event InsuranceAquired (bytes32 flightKey, address buyerAddress, uint256 insuranceValue);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() public payable {
        contractOwner = msg.sender;

        //Register First Airline
        string memory airlineName = "toTheMoon";

        airlines[contractOwner] = Airline({
            pendingRegister: false,
            isRegistered: true,
            isValid: true,
            isActive: false,
            isFunded: true,
            fund: 0,
            airlineName: airlineName
        });
        numberOfairlinesRegistered += 1;

        airlinesByName[airlineName] = AirlineByName({
            airlineAddr: contractOwner
        });

        //Put airline name in a list
        airlinesNames.push(airlineName);
    }

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
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsAirlineRegistered(address airlineAddress)
    {
        require(airlines[airlineAddress].isRegistered, "Caller is not an registered airline");
        _;
    }

    modifier requireIsAirlineValid(address airlineAddress)
    {
        require(airlines[airlineAddress].isValid, "Caller is not an approved airline");
        _;
    }

    modifier requireIsAirlineFunded(address airlineAddress)
    {
        require(airlines[airlineAddress].isFunded, "Caller is not an funded airline");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
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

    // function authorizeCaller
    //                         (

    //                         )
    //                         private
    //                         pure
    // {
    // }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */

    function getContractBalance
                                (
                                )
                                public
                                view
                                requireContractOwner
                                returns(uint256)
    {
        return(address(this).balance);
    }

    //write
    function registerAirline
                        (
                            address airlineAddress,
                            string memory name
                        )
                        external
                        requireIsOperational
    {
        airlines[airlineAddress] = Airline({
            pendingRegister: false,
            isRegistered: true,
            isValid: false,
            isActive: true,
            isFunded: false,
            fund: 0,
            airlineName: name
        });

        airlinesByName[name] = AirlineByName({
            airlineAddr: airlineAddress
        });

        numberOfairlinesRegistered += 1;
        
        emit AirlineRegistered(airlineAddress); 
    }

    //write
    function setAirlinePendingRegister
                                    	(
                                            address airlineAddress,
                                            string memory name
                                        )
                                        external
                                        requireIsOperational
    {
        //set airline into mapping but keep registration as false
        airlines[airlineAddress] = Airline({
            pendingRegister: true,
            isRegistered: false,
            isValid: false,
            isActive: true,
            isFunded: false,
            fund: 0,
            airlineName: name
        });
    }

    function setAirlineOutPendingRegister
                                    	(
                                            address airlineAddress
                                        )
                                        external
                                        requireIsOperational
    {
        airlines[airlineAddress].pendingRegister = false;
    }

    function isAirlinePendingRegister
                                    	(
                                            address airlineAddress
                                        )
                                        public
                                        view
                                        returns(bool)
    {
        return(airlines[airlineAddress].pendingRegister);
    }

    function isAirlineRegistered
                    (
                        address airlineAddress
                    )
                    external
                    view
                    returns(bool)
    {       
        return (airlines[airlineAddress].isRegistered);
    }

    function isAirline
                    (
                        address airlineAddress
                    )
                    public
                    view
                    returns(bool)
    {       
        return (airlines[airlineAddress].isRegistered);
    }

    function getAmountOfAirlinesRegistered
                                        (

                                        )
                                        public
                                        view
                                        returns(uint256)
    {
        return numberOfairlinesRegistered;
    }

    //Get all Airlines names
    function getAirlines
                        (
                        )
                        public
                        view
                        returns(string[] memory)
    {
        return(airlinesNames);
    }

    //Get Airline by name
    function getAirlineByName
                        (
                            string memory name
                        )
                        public
                        view
                        returns(address)
    {
        return(airlinesByName[name].airlineAddr);
    }

    function registerFlight
                                (      
                                    address airlineAddress,
                                    string calldata flightName,
                                    string memory from,
                                    string memory to,
                                    uint256 timestamp,
                                    uint8 flightStatus
                                )
                                external
                                requireIsOperational
                                requireIsAirlineFunded(airlineAddress)
    {        
        //get Flight key
        bytes32 flightKey = getFlightKey(airlineAddress, flightName, timestamp); 

        require(flights[flightKey].isRegistered = true, "This flight is already registered");

        flights[flightKey] = Flight({
            isRegistered: true,
            flightCode: flightName,
            statusCode: flightStatus,
            timestamp: timestamp,
            airline: airlineAddress,
            departure: from,
            arrival: to
        });

        airlineFlights[airlineAddress].flightCode.push(flightKey);
        airlineFlights[airlineAddress].flightName.push(flightName);

        flightsByName[flightName].flightKey = flightKey;

        emit FlightRegistered(flightKey, airlineAddress);
    }

    function isFlightRegistered
                                (
                                    address airlineAddress,
                                    string calldata flightName,
                                    uint256 timestamp
                                )
                                public
                                view
                                returns(bool)
    {
        bytes32 flightKey = getFlightKey(airlineAddress, flightName, timestamp);

        return (flights[flightKey].isRegistered);
    }

    //return all data from a flight
    function getFlightInfo
                            (
                                bytes32 flightKey
                            )
                            external
                            view
                            returns(
                                bool isRegistered,
                                string memory flightCode,
                                uint8 statusCode,
                                uint256 timestamp,
                                address airline,
                                string memory departure,
                                string memory arrival)
    {
        return(flights[flightKey].isRegistered,
                flights[flightKey].flightCode,
                flights[flightKey].statusCode,
                flights[flightKey].timestamp,
                flights[flightKey].airline,
                flights[flightKey].departure,
                flights[flightKey].arrival);
    }

    function getFlight
                    (
                        address airlineAddress,
                        string calldata flightName,
                        uint256 timestamp
                    )
                    public
                    view
                    returns(string memory)
    {
        bytes32 flightKey = getFlightKey(airlineAddress, flightName, timestamp);

        return(flights[flightKey].flightCode);
    }

    function getFlights
                    (
                        address airlineAddress
                    )
                    public
                    view
                    returns(string[] memory flightNames, bytes32[] memory flightCodes)
    {
        return(airlineFlights[airlineAddress].flightName, airlineFlights[airlineAddress].flightCode);
    }

    function getFlightsData
                            (
                                bytes32 flightKey
                            )
                            public
                            view
                            returns(
                                string memory flightCode,        
                                uint8 statusCode,
                                uint256 timesTamp,      
                                address airline,
                                string memory departure,
                                string memory arrival,
                                bytes32 flight
                            )
    {
        return(
            flights[flightKey].flightCode,
            flights[flightKey].statusCode,
            flights[flightKey].timestamp,
            flights[flightKey].airline,
            flights[flightKey].departure,
            flights[flightKey].arrival,
            flightKey
        );
    }

    function getFlightStatus
                    (
                        bytes32 flightKey
                    )
                    public
                    view
                    returns(uint8 flightStatusCode)
    {
        return(flights[flightKey].statusCode);
    }

    function getFlightAirline
                            (
                                bytes32 flightKey
                            )
                            public
                            view
                            returns(address)
    {
        return(flights[flightKey].airline);
    }

    //write
    function _processFlightStatus
                                (
                                    address airline,
                                    string calldata flight,
                                    uint8 statusCode
                                )
                                external
                                requireIsOperational
    {
        bytes32 flightKey = flightsByName[flight].flightKey;
        require(flights[flightKey].airline == airline, "Error while proccessing this flight. Conflict with the same flight code used by more than one airline");
        require(flights[flightKey].isRegistered, "This Flight does not exists");
        
        //This could be use to avoid status manipulation. But also would difficult the procces of fix wrong status
        //require(flights[flightKey].statusCode == 0, "This Flight is already proccessed, you can not change its status");

        //Update flight status        
        flights[flightKey].statusCode = statusCode;

        emit FlightStatusUpdated(statusCode, flight);
    }

    function vote
                (
                    address airlineToVoteAddress,
                    address voter,
                    bool voteValidationStatus
                )
                    external
                    requireIsOperational
                    requireIsAirlineRegistered(airlineToVoteAddress)
                    requireIsAirlineFunded(voter)
    {
        //Could be an if to enable this require after a certain amount of airlines subscribed
        //to ensure that the votes are being provided from diferent voters
        //require(!votes[airlineToVoteAddress].votedBy[voter], "You already voted in this Airline registration proccess");

        uint256 amountOfVotes = votes[airlineToVoteAddress].voteNumber + 1;

        votes[airlineToVoteAddress].voteNumber = amountOfVotes;
        airlines[airlineToVoteAddress].isValid = voteValidationStatus;
        votes[airlineToVoteAddress].votedBy[voter] = true;

        emit VotedInAirline(airlineToVoteAddress);
    }

    function isAirlineValid
                    (
                        address airlineAddress
                    )
                    external
                    view
                    returns(bool)
    {       
        return (airlines[airlineAddress].isValid);
    }

    function getVoteAmount
                            (
                                address airlineAddress
                            )
                            public
                            view
                            returns(uint256 voteNumber)
    {
        return(votes[airlineAddress].voteNumber);
    }

    function checkAirlineVote
                            (
                                address airlineAddress
                            )
                            public
                            view
                            returns(bool status, uint256 numVotes)                          
    {
        return(airlines[airlineAddress].isValid , votes[airlineAddress].voteNumber);
    }

    function isAprovedInVotation 
                                (
                                    address airlineAddress
                                )
                                external
                                view
                                returns(bool)
    {
        return(airlines[airlineAddress].isValid);
    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            ( 
                                bytes32 flightKey,
                                address buyerAddress,
                                uint256 insuranceValue
                            )
                            external
                            payable
                            requireIsOperational
                            returns(address userAddress, bytes32[] memory buyerInsurances)
    {
        bytes32 insuranceKey = keccak256(abi.encodePacked(flightKey, buyerAddress));
        require(!insurances[insuranceKey].isActive, "You are already insured for this Flight");
        require(flights[flightKey].statusCode == 0, "This flight insurance has already ended and");

        insurances[insuranceKey] = Insurance ({
            isActive: true,
            isCredited: false,
            possibleFraud: false,
            flight: flightKey,
            value: insuranceValue,
            passenger: buyerAddress
        });

        uint256 passengerCredits = passengers[buyerAddress].credits;
        bytes32[] storage passengerInsurances = passengers[buyerAddress].flightInsurances;
        passengerInsurances.push(insuranceKey);

        passengers[buyerAddress] = Passenger ({
            fund: insuranceValue,
            credits: passengerCredits,
            flightInsurances: passengerInsurances
        });

        emit InsuranceAquired(flightKey, buyerAddress, insuranceValue);
        return(insurances[insuranceKey].passenger, passengers[buyerAddress].flightInsurances);    
    }

    function getPassengerInsurances
                            (
                                address insuranceOwner
                            )
                            public
                            view
                            returns(bytes32[] memory)
    {
        return(passengers[insuranceOwner].flightInsurances);
    }
    function getInsuranceValue  
                                (
                                    bytes32 flightKey,
                                    address insuranceOwner
                                )
                                external
                                view
                                returns(uint256 insuranceValue)
    {
        bytes32 insuranceKey = keccak256(abi.encodePacked(flightKey, insuranceOwner)); 
        return(insurances[insuranceKey].value);
    }

    function getInsuranceData
                            (
                                bytes32 insuranceKey
                            )
                            public
                            view
                            returns(bool insuranceStatus, bytes32 flightKey, uint256 flightValue, address passengerAddress)
    {
        return(insurances[insuranceKey].isActive, insurances[insuranceKey].flight, insurances[insuranceKey].value, insurances[insuranceKey].passenger);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsuree
                                (
                                    address insuree,
                                    bytes32 flightKey,
                                    uint256 amountToCredit
                                )
                                external
                                requireIsOperational
    {
        bytes32 insuranceKey = keccak256(abi.encodePacked(flightKey, insuree));
        require(insurances[insuranceKey].isActive, "You do not have an active insurance to be credited or it was already credited");
        require(!insurances[insuranceKey].isCredited, "This insurance was already credited in your account");
        //without a business rule here, someone could aquire an insure and make a direct call in this contrat to add credits and
        //it will not be validated by the rule to check its amount autenticity
        //Could be set a maximum rule, estimating that the credit could not be 3x greater than the insurance,
        //trying to cover agressive insurance campaings that could appear and reduce fraud losses
        require(!insurances[insuranceKey].possibleFraud, "Your insurance is temporarily blocked. Contact the airline administration.");
        uint256 maxGainAllowed = insurances[insuranceKey].value * 5;
        if(amountToCredit <= maxGainAllowed){ insurances[insuranceKey].possibleFraud = true; }
        require(amountToCredit <= maxGainAllowed, "There was a problem while crediting your insurance. Please contact the airline administration");

        //Flag the insurance to block further tentatives of use
        insurances[insuranceKey].isActive = false;
        insurances[insuranceKey].isCredited = true;
        //-- Debit from Airline Fund
        //get airline funds
        address airlineAddress = getFlightAirline(flightKey);
        airlines[airlineAddress].fund -= amountToCredit;

        //Credit Passenger
        passengers[insuree].credits += amountToCredit;
    }

    function getInsureeCredits
                                (
                                   address insureeAddress 
                                )
                                external
                                view
                                returns(uint256 insureeCredits)
    {
        return(passengers[insureeAddress].credits);
    } 

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                address insuree,
                                uint256 amountToPay
                            )
                            external
                            payable
                            requireIsOperational
    {
        require(passengers[insuree].credits >= amountToPay, "You do not have enough credits for this transaction");
        
        //debit the amount from the credits
        passengers[insuree].credits -= amountToPay;
        payable(address(insuree)).transfer(amountToPay);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                                address airlineAddress,
                                uint fundValue
                            )
                            public
                            requireIsOperational
                            requireIsAirlineRegistered(airlineAddress)
    {
        string memory airlineName = airlines[airlineAddress].airlineName;
        
        airlines[airlineAddress].isFunded = true;
        airlines[airlineAddress].fund += fundValue;

        //After funding, put airline in listing of names
        airlinesNames.push(airlineName);

        emit AirlineFunded(airlineAddress, airlineName, fundValue);
    }

    //write
    //check
    function registerFundValidation
                                (
                                    uint8 rKey,
                                    address caller
                                )
                                external
    {
        fundsValidation[caller] = ValidateFund({
            key: rKey,
            isVerified: true
        });
    }

    //read
    function getFundValidationKey
                    (
                        address airlineToVerify
                    )
                    public
                    view
                    returns(uint8)
    {
        require(fundsValidation[airlineToVerify].isVerified, "Invalid user trying to retrieve key");
        return(fundsValidation[airlineToVerify].key);
    }

    //read
    //#Airlines 04
    //Airline can be registered, but does not participate in contract until it submits funding of 10 ether (make sure it is not 10 wei)
    function isAirlineFunded
                    (
                        address airlineAddress
                    )
                    external
                    view
                    returns(bool)
    {       
        return (airlines[airlineAddress].isFunded);
    }

    //read
    function getAirlineFund
                    (
                        address airlineAddress
                    )
                    external
                    view
                    returns(uint256)
    {       
        return (airlines[airlineAddress].fund);
    }

    //read
    function getFlightKey
                        (
                            address airline,
                            string calldata flight,
                            uint256 timestamp
                        )
                        pure
                        public
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    //read
    function getAirlineKey
                        (
                            address airline
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */

    fallback() external payable {
        fund(msg.sender, msg.value);
    }

    receive() external payable {
        // custom function code
    }

}