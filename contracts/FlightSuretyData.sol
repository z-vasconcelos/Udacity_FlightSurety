// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
        string flightCode;
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }
    mapping(bytes32 => Flight) private flights;

    struct Airline {
        bool isRegistered;
        bool isValid;      //true if airline received minimum vote amount for validation
        bool isActive;     //true if airline is currenctly ative/flying
        bool isFunded;     //true if airline has received the fund registrationFee
        uint256 fund;
        string airlineName;
    }
    mapping(address => Airline) private airlines;

    struct PendingRegisters {
        bool inLine;
        bool isApproved;
    }

    mapping(address => PendingRegisters) private pendingRegister;

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

    uint256 public numberOfairlinesRegistered = 0;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event FirstAirlineRegistered (address indexed account, bool registrationStatus);
    event AirlineRegistered (address indexed account);
    event AirlineFunded (address indexed account);
    event VotedInAirline (address indexed account);

    event FlightRegistered (bytes32 flightKey, address indexed account);
    event FlightStatusProcessed (bytes32 flightKey, uint8 statusCode);

    //debug events
    event AirlineVotes(uint256 votes);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor() public payable {
        contractOwner = msg.sender;

        //Register First Airline
        airlines[contractOwner] = Airline({
            isRegistered: true,
            isValid: true,
            isActive: false,
            isFunded: true,
            fund: 0,
            airlineName: "toTheMoon"
        });
        numberOfairlinesRegistered += 1;
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
                            string calldata name
                        )
                        external
                        requireIsOperational
    {
        airlines[airlineAddress] = Airline({
            isRegistered: true,
            isValid: false,
            isActive: true,
            isFunded: false,
            fund: 0,
            airlineName: name
        });

        numberOfairlinesRegistered += 1;

        emit AirlineRegistered(airlineAddress); 
    }

    //write
    function setAirlinePendingRegister
                                    	(
                                            address airlineAddress
                                        )
                                        external
                                        requireIsOperational
    {
        pendingRegister[airlineAddress] = PendingRegisters({
            inLine: true,
            isApproved: false
        });
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
        return(pendingRegister[airlineAddress].inLine);
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

    //write
    function registerFlight
                                (      
                                    address airlineAddress,
                                    string calldata flightName,
                                    uint256 timestamp,
                                    uint8 flightStatus
                                )
                                external
                                requireIsOperational
                                requireIsAirlineFunded(airlineAddress)
                                returns(bool)
    {        
        //get Flight key
        bytes32 flightKey = getFlightKey(airlineAddress, flightName, timestamp);

        flights[flightKey] = Flight({
            flightCode: flightName,
            isRegistered: true,
            statusCode: flightStatus,
            updatedTimestamp: timestamp,
            airline: airlineAddress
        });

        emit FlightRegistered(flightKey, airlineAddress);
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
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        // require(!isFlightLanded(flightKey), "Flight has already landed.");
        if (flights[flightKey].statusCode == 0) {
            flights[flightKey].statusCode = statusCode;
            
            //Pay credit for passenger
            // if (statusCode == 20) {
            //     creditInsurees(flightKey);
            // }
        }
        emit FlightStatusProcessed(flightKey, statusCode);
    }

    //read
    function isFlightRegistered
                                (
                                    bytes32 flightKey
                                )
                                public
                                view
                                returns(bool)
    {
        return (flights[flightKey].isRegistered);
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

        //this same code worked in remix and calling direct from truffle console, but I always gor "reverted" calling from dapp
        //It would be used to check if the voter had already voted in the specific airline.
        //votes[airlineToVoteAddress].votedBy.push(voter);

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
        //*****
        //to do
        //Insert a payout check logic to block funds
        //check amount sent to contract
        //require(fundsValidation[airlineAddress].key == rkey, "Not a valid funding external call");   
        
        ///verifyIfHasFunds
        airlines[airlineAddress].isFunded = true;
        airlines[airlineAddress].fund = fundValue;

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
                            string memory flight,
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