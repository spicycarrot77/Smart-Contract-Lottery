// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions


// SPDX-License-Identifier: MIT~

pragma solidity ^0.8.19;

  /** IMPORTS */

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/libraries/VRFV2PlusClient.sol";



/**
 * @title A simple Raffle contract
 * @author Jeeshan Sheikh
 * @dev Implements chainlink VRFv2.5
 * @notice This contract is a basic implementation of a raffle system.
 */

contract Raffle is VRFConsumerBaseV2Plus {
   // we are inheriting from VRFConsumerBaseV2Plus to use Chainlink VRF for randomness
   // we also have to add contructors from this inherited contract to our contract

    /** ERRORS */
     error Raffle__NotEnoughETHSent();
     error Raffle__NotEnoughTimePassed();
     error Raffle__TransferFailed();
     error Raffle__RaffleNotOpen();
     error Raffle__UpkeepNotNeeded();

    /** Type Declarations */
     enum RaffleState{  //this needs to be mentioned in constructor
        OPEN,  //0
        CALCULATING //1
     }

    /**State Variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_keyHash;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    // constant and immutable variables are usually written in the constructor




    /** EVENTS - we can have only 3 indexed events */ 
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);


   /**  CONSTRUCTOR */

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator // we actually pass vrfcoordinator in our constructor and it gets passed onto the VRFConsumerBaseV2Plus' constructor
    , uint256 subscriptionId,
        bytes32 gasLane, // keyHash 
        uint32 callbackGasLimit)VRFConsumerBaseV2Plus(vrfCoordinator) {  // address of the on chain vrfcoordinator contract which provides random no. it differs from chain to chain and your contract talks to it to get random numbers.
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_lastTimeStamp = block.timestamp; // initialize the last timestamp to the current block timestamp
        s_raffleState = RaffleState.OPEN; // initialize the raffle state to open
        }
    /** FUNCTIONS */

    
    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH sent");
        //require(msg.value >= i_entranceFee, Raffle__NotEnoughETHSent());
        // having reverts as strings is not very gas efficient

       if(msg.value < i_entranceFee) {
             revert Raffle__NotEnoughETHSent();
        }
        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        // Logic to enter the raffle
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);  //anytime  we update the storage of the contract, we should emit an event here we have pushed msg.sender to the players array
    }

    // the checkupkeep and performUpkeep functions are 
    // the functions that Chainlink Keepers will call to 
    // automate the process of picking a winner

    function checkUpkeep(bytes memory /*checkData*/) public view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        // whenevr we see a variable commenteed out, it means that we are not using it in the function


        //we need to check if the a)raffle is open b)certain amount of time has passed c)there are players in the raffle d)there are funds in the raffle
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = (address(this).balance > 0);
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, ""); // performData is not used in this case, so we return an empty bytes array
    }


    // function pickWinner() external {
        
    // // check to see if enough time has passed
    // if (block.timestamp - s_lastTimeStamp < i_interval) {          block.timestamp is the current time
    //     revert Raffle__NotEnoughTimePassed();
    // }


     function performUpkeep(bytes calldata /*perform data */) external {
    // this function is called by Chainlink Keepers when checkUpkeep returns true
    // check to see if enough time has passed
    (bool upkeepNeeded, ) = checkUpkeep("");
    //if the param in checkUpKeep was bytes call data then we cannot leave the input blank over here, but in this case its is memory
    if (!upkeepNeeded) {
        revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
    }

    s_raffleState = RaffleState.CALCULATING; // set the raffle state to calculating so that no one can enter the raffle while we are picking a winner

    VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest (
        {
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            } //this entire part of code is where we are creating a rand no. request
            );
//VRFV2PlusClient is a type of coordinator contract whihc has RandomWordsRequest, a struct defined in the VRFV2... contract. When we pass this struct through the function requestRandomWords in the s_vrfCoordinator contract we get requestId

    uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
  // s_vrfcoordinator variable is a variable in the VRDConsumerBaseV2Plus contract which we have inherited
        //it is refernce to the vrfcoordinator address passed in the constructor  
    emit RequestedRaffleWinner(requestId); // we emit an event here to log the requestId
    }
    


    //this is the function is virtual in the abstract VRFConsumerV2Base contract so we can modify it acc to our needs
    //the s_vrfcoordinator contract calls rawfulfillrandomwords function which has fulfillrandomwords in it so this gets automaticlly called
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {

    uint256 indexOfWinner = randomWords[0] % s_players.length; // get a random index from the players array
    address payable recentWinner = s_players[indexOfWinner]; // get the winner from the players array
    s_recentWinner = recentWinner; // set the recent winner
    s_raffleState = RaffleState.OPEN; // set the raffle state back to open
   
   
    s_players = new address payable[](0); // reset the players array
    s_lastTimeStamp = block.timestamp; // update the last timestamp to the current block timestamp
    emit WinnerPicked(s_recentWinner); // emit an event for the winner

     // transfer the balance of the contract to the winner
     // we use call instead of transfer because transfer has a gas limit of 2300 which is not enough for some contracts
     // call is more gas efficient and allows us to send more ETH
    (bool success, ) = recentWinner.call{value: address(this).balance}(""); // transfer the balance of the contract to the winner
     if (!success) {
        revert Raffle__TransferFailed();
     }

    /**Getter Functions */

   function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
   }
   function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
   }
   function getPlayersArray(uint256 indexOfPlayer) external view returns (address){
     return s_players[indexOfPlayer];
   }
   function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
   }
   function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
   }
   function getRecentWinner() external view returns (address) {
        return s_recentWinner;
   }
   function getInterval() external view returns (uint256) {
        return i_interval;  
   }
    function getSubscriptionId() external view returns (uint256) {
          return i_subscriptionId;
    }       
     
}
}

