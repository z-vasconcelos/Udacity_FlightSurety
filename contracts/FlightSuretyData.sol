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
        address[] votedBy;
    }
    
    mapping(address => Vote) public votes;

    //mapping(address=> mapping (uint => address)) public votersAdresses;
    mapping(address => address[]) votersAdresses;

    struct ValidateFund {
        uint8 key;
        bool isVerified;
    }
    mapping(address => ValidateFund) private fundsValidation;

    struct Passenger {
        bytes32[] flightsRegistered;
    }
    mapping(address => Passenger) private passengers;

    uint256 private numberOfairlinesRegistered = 0;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event FirstAirlineRegistered (address indexed account, bool registrationStatus);
    event AirlineRegistered (address indexed account);
    event AirlineFunded (address indexed account);
    event VotedInAirline (address indexed account);

    event FlightRegistered (bytes32 flightKey, address indexed account);
    event FlightStatusProcessed (bytes32 flightKey, uint8 statusCode, string flightCode);

    //debug events
    event AirlineVotes(uint256 votes);

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
        //push airline address into a list of pending registration
        //pendingRegister.push(airlineAddress);

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

    //write
    function setAirlineOutPendingRegister
                                    	(
                                            address airlineAddress
                                        )
                                        external
                                        requireIsOperational
    {
        //On Airlines Mapping, flag "pendingRegister" as false
        airlines[airlineAddress].pendingRegister = false;

        //remove airline from pendingRegistration
        //delete pendingRegister[airlineAddress];
    }

    //read
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

    //read
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

    //read
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

    //read
    function getAmountOfAirlinesRegistered
                                        (

                                        )
                                        public
                                        view
                                        requireIsOperational
                                        returns(uint256)
    {
        return numberOfairlinesRegistered;
    }

    //Get all Airline name
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

    //write
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
    {        
        //get Flight key
        bytes32 flightKey = getFlightKey(airlineAddress, flightName, timestamp); 

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

    //read
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
                    returns(string[] memory flightNames,bytes32[] memory flightCodes)
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
                                bool isRegistered,
                                string memory flightCode,        
                                uint8 statusCode,
                                uint256 timesTamp,      
                                address airline,
                                string memory departure,
                                string memory arrival
                            )
    {
        return(
            flights[flightKey].isRegistered,
            flights[flightKey].flightCode,
            flights[flightKey].statusCode,
            flights[flightKey].timestamp,
            flights[flightKey].airline,
            flights[flightKey].departure,
            flights[flightKey].arrival
        );
    }

    function getFlightStatus
                    (
                        bytes32 flightCode
                    )
                    public
                    view
                    returns(uint8 flightStatusCode)
    {
        return(flights[flightCode].statusCode);
    }

    //write
    function processFlightStatus
                                (
                                address airline,
                                string calldata flight,
                                uint256 timestamp,
                                uint8 statusCode
                                )
                                external
                                requireIsOperational
    {
        // require(!isFlightLanded(flightKey), "Flight has already landed.");
        bytes32 flightKey = flightsByName[flight].flightKey;

        //Updata flight status        
        flights[flightKey].statusCode = statusCode;
        
        //Pay credit for passenger
        // if (statusCode == 20) {
        //     creditInsurees(flightKey);
        // }

        emit FlightStatusProcessed(flightKey, flights[flightKey].statusCode, flight);
    }

    //write
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
                    returns(address votedByAddress)
    {
        uint256 amountOfVotes = votes[airlineToVoteAddress].voteNumber + 1;

        votes[airlineToVoteAddress].voteNumber = amountOfVotes;
        airlines[airlineToVoteAddress].isValid = voteValidationStatus;
        votes[airlineToVoteAddress].votedBy.push(voter);

        emit VotedInAirline(airlineToVoteAddress);
        return(voter);
    }

    //read
    function getVoters
                    (
                        address airlineAddress
                    )
                    public
                    view
                    returns(address[] memory airlineAddressVotes)
    {
        return(votes[airlineAddress].votedBy);
    }

    //read
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

    //read
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

    //read
    function checkAirlineVote
                            (
                                address airlineAddress
                            )
                            public                            
    {
        emit AirlineVotes(votes[airlineAddress].voteNumber);
        //returns(bool status, uint256 numVotes)
        //return(votes[airlineAddress].approvedInVotation , votes[airlineAddress].voteNumber);
    }

    //read
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
                            )
                            external
                            payable
                            requireIsOperational
    {

    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                )
                                external
                                requireIsOperational
    {
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                            )
                            external
                            payable
                            requireIsOperational
    {
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
                            returns(bool funded)
    {
        string memory airlineName = airlines[airlineAddress].airlineName;
        
        //*****
        //to do
        //Insert a payout check logic to block funds
        //check amount sent to contract
        //require(fundsValidation[airlineAddress].key == rkey, "Not a valid funding external call");   
        
        ///verifyIfHasFunds
        airlines[airlineAddress].isFunded = true;
        airlines[airlineAddress].fund = fundValue;

        //After funding, put airline in listing of names
        airlinesNames.push(airlineName);

        return(airlines[airlineAddress].isFunded);
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
                        internal
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