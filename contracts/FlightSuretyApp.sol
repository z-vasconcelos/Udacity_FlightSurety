// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
    uint256  private constant AIRLINE_REGISTRATION_FEE = 10 ether;
    uint256  AIRLINE_AMOUNT_FOR_CONSENSUS = 50;

    //Votes Business Rules
    uint256  private VOTES_MIN_FOR_REGISTRATION = 4;

    //use to set dataContract inside constructor
    address payable dataContractAddress;

    address payable contractOwner;          // Account used to deploy contract
    bool private operational = true;        // Blocks all state changes throughout the contract if fals

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event MinVotesForAirlineRegisterUpdated (uint8 numberOfVotesRequested);
    event testRegister (uint airlineRegNumb);
 
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

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function getDataContractAddress() public view returns(address){
        return(dataContractAddress);
    }

    //write
    function registerAirline
                            (
                                address airlineToRegisterAddress,
                                string calldata airlineName
                            )
                            public
                            requireIsOperational
    {
        require(!flightSuretyData.isAirlineRegistered(airlineToRegisterAddress), "Airline is already registered.");

        uint256 numberOfRegisteredAirlines = flightSuretyData.getAmountOfAirlinesRegistered();

        //Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines
        if (numberOfRegisteredAirlines >= AIRLINE_AMOUNT_FOR_CONSENSUS){

            //Put Airline in Pending Register
            flightSuretyData.setAirlinePendingRegister(airlineToRegisterAddress);

        //Only existing airline may register a new airline until there are at least FOUR airlines registered
        } else if(numberOfRegisteredAirlines <= 3){
            
            require(flightSuretyData.isAirlineRegistered(msg.sender), "Caller is not a registered airline. Minimun amount airlines not achieved for non registered airline be able to register new ones");
            flightSuretyData.registerAirline(airlineToRegisterAddress, airlineName);
            emit testRegister(numberOfRegisteredAirlines + 1); 

        } else {
            flightSuretyData.registerAirline(airlineToRegisterAddress, airlineName);
            emit testRegister(numberOfRegisteredAirlines + 1); 
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
                                    string calldata flight,
                                    uint256 timestamp
                                )
                                external
                                requireIsOperational
                                requireIsAirlineFunded
    {   
        uint8 flightStatus = STATUS_CODE_UNKNOWN;

        // flyKey = getFlightKey(airlineAddress, flight, timestamp);   

        flightSuretyData.registerFlight(airlineAddress, flight, timestamp, flightStatus);
    }

   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
                                requireIsOperational
    {
        flightSuretyData.processFlightStatus(airline, flight, timestamp, statusCode);
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

        emit OracleRequest(index, airline, flight, timestamp);
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
        //                returns(bool funded, address airlineFunded, uint val, address contractAddress, address dataC, uint bal)
        
        //Check Fund value
        require(msg.value >= AIRLINE_REGISTRATION_FEE, "Minimum funding is at last 10 Ether");

        //uint8 rKey = uint8(uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty)))%251);
        //bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 

        //flightSuretyData.registerFundValidation(rKey, msg.sender);
        //bool isFunded = flightSuretyData.fund(msg.sender, msg.value);
        flightSuretyData.fund(msg.sender, msg.value);

        //ref https://ethereum.stackexchange.com/questions/65693/how-to-cast-address-to-address-payable-in-solidity-0-5-0
        //FlightSuretyData addr = FlightSuretyData(dataContractAddress);
        //address payable wallet = address(uint160(address(addr)));

        payable(address(dataContractAddress)).transfer(msg.value);
        //address(flightSuretyData).transfer(msg.value);

        //flightSuretyData.fund(msg.sender, rKey);        

        //return(true, msg.sender, msg.value, flightSuretyData, dataContractAddress, address(msg.sender).balance);
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
                returns(string memory obs, bool status, address votedBy, address toVote)
    {
        require(flightSuretyData.isAirlineRegistered(airlineToVoteAddress), "You can not vote in a airline that is not registered");

        bool voteValidationStatus;        
        uint256 numberOfRegisteredAirlines = flightSuretyData.getAmountOfAirlinesRegistered();
        uint256 voteAmount = flightSuretyData.getVoteAmount(airlineToVoteAddress);
        string memory observation = "N/A";
        
        //#Airlines 03
        //Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines
        
        //check if current number of registered airlines is less than 50
        if(numberOfRegisteredAirlines < AIRLINE_AMOUNT_FOR_CONSENSUS){
            //If it is less, check if airline has more than 4 votes to be validated
            if((voteAmount + 1) >= VOTES_MIN_FOR_REGISTRATION){
                voteValidationStatus = true;
                observation = "voteAmount > VOTES_MIN_FOR_REGISTRATION";
            } else {
                voteValidationStatus = false;
                observation = "voteAmount < VOTES_MIN_FOR_REGISTRATION";
            }
        } else {
            //If it is more or equal 50, check if airline has votes from more than 50% of the registered airlines to be validated
            if(voteAmount > (numberOfRegisteredAirlines/2)){
                voteValidationStatus = true;
                observation = "voteAmount > (numberOfRegisteredAirlines/2)";
            } else {
                voteValidationStatus = false;
                observation = "voteAmount < (numberOfRegisteredAirlines/2)";
            }        
        }

        address validationStatus = flightSuretyData.vote(airlineToVoteAddress, msg.sender, voteValidationStatus);   
        return(observation, voteValidationStatus, validationStatus, airlineToVoteAddress);
    }

    function checkAirlineVote
                            (
                                address airlineAddress
                            )
                            public
    {
        flightSuretyData.checkAirlineVote(airlineAddress);
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
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


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
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3] memory returnData)
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
                        requireIsOperational
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

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        internal
                        pure
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3] memory dataReturn)
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
    function registerAirline(address airlineAddress, string calldata airlineName) virtual external;
    function registerFlight(address airlineAddress, string calldata flight, uint256 timestamp, uint8 flightStatus) virtual external;
    function getAmountOfAirlinesRegistered() virtual public view returns(uint256);
    function setAirlinePendingRegister(address airlineAddress) virtual external;
    //airline fund
    function fund(address airlineAddress, uint fundValue) virtual external returns(bool);
    function registerFundValidation(uint8 rKey, address caller) virtual external;  
    //airline vote
    function isAprovedInVotation(address airlineAddress) virtual external view returns(bool);
    function vote(address airlineToVoteAddress, address voter, bool voteValidationStatus) virtual external returns(address votedBy);
    function checkAirlineVote(address airlineAddress) virtual external;
    function getVoteAmount(address airlineAddress) virtual public view returns(uint256);
    //flight
    function processFlightStatus(address airline, string calldata flight, uint256 timestamp, uint8 statusCode) virtual external;
}  
    

    
