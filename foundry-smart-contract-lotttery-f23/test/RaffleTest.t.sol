// SPDX-License-Identifier: MIT~


//to perform any test in the terminal we write forge test --mt "test-name" -vvvv
//forge coverage tells you about how much code coverage you have
//forge coverage --report debug tells you whihc lines we havent tested


pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig} from "script/HelperConfig.s.sol"; 
import {CodeConstants} from "script/HelperConfig.s.sol";

contract RaffleTest is Test, CodeConstants {
      Raffle public raffle;
      HelperConfig public helperConfig;
      address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint256 entranceFee;
        uint256 interval;
        uint256 callbackGasLimit;

      address public PLAYER = makeAddr("player"); //creating a mock player
      uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

      event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

      function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle,helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        //now this config variisble is a struct and it'll get all the off chain info from different chains
        entranceFee = config.entranceFee;
        interval = config.interval;
            vrfCoordinator = config.vrfCoordinator;
            subscriptionId = config.subscriptionId;
            gasLane = config.gasLane;
           callbackGasLimit = config.callbackGasLimit;

           vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
           //player gets starting balance to spend
      }

      function testRaffleStartsInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
      }

      function testRaffleRevertsWhenYouDontPayEnough() public view {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__NotEnoughETHSent.selector);
        //we are expecting a revert with a very specific error
        raffle.enterRaffle(); //this will revert as player didnt sent any money
      }

      function testRaffleRecordsWhenTheyEnter() public {
        //ARRANGE
        vm.prank(PLAYER);
        //ACT
        raffle.enterRaffle{value: entranceFee}();
        //this is how you enter amount while doing test but this will fail as we havent given our player any omey 
        //ASSERT
        address playerRecorder = raffle.getPlayersArray(0);
        assert(playerRecorder==PLAYER);
      }

      function testEnteringRaffleEmitsEvent() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle)); //since in an event we can only have 3 index and 1 spot is for non index data or additional event(if it there we write true) we write true when there is an indexed event false is either cuz there is no event or no indexed event
        //for this we need the actaul events mentioned above in the test contract

        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

}
      function testDontAllowEntranceWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); //allows us to change the block timestamp
        vm.roll(block.number + 1);

        raffle.performUpkeep(""); // changes the state to calculating

        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        

      }

     function testCheckUpkeepReturnsFalseIfNoBalance() public  {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
     }
     function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        //arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep(""); // changes the state to calculating
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assert(!upkeepNeeded);
     }
     function testCheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed() public 
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval - 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
     }
     function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded); }

      /*/////////////////////////////////////////////////////////////////////////
                        performUpkeep
      //////////////////////////////////////////////////////////////////////////*/
      // perfrom upkeep can only run if checkupkeep is true
      function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);  

        raffle.performUpkeep(""); // should not revert, if this function reverts the test will be unsuccesfull
      }
 function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
  //when we test an error which has parameters in its custom error then we need the declare variable first
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = 1;
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, uint256(raffleState)));
        raffle.performUpkeep("");
      }

      modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);  
        _;
      }

      function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
        
        vm.recordLogs(); //records all the logs(data in event emitted) of the function called just after it
        raffle.performUpkeep("");
        //whtever events are emitted in this function are recorded now 
        Vm.Log[] memory entries = vm.getRecordedLogs(); //get all the logs that happened during the last transaction
        bytes32 requestId = entries[1].topics[1]; 
        //this is how you get the first event data emmited whihc is the requestId

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        //ASSERT
        assert(uint256(requestId) > 0);
        //checking if there is a requestId or not
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        //or assert(uint256(raffleState) == 1);

      }

      /*/////////////////////////////////////////////////////////////////////////
                        fulfillRandomWords
      //////////////////////////////////////////////////////////////////////////*/
      // We need to first test that fulfillRandomWords can only be called after performUpkeep
      // Then we will test the full functionality of it

      modifier skipFork() {
        if (block.chainid == LOCAL_CHAIN_ID) {
            return;
        }
        _;
      }

      modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);  
        _;
      }
     // fulfillRnadomWords can only be called after performUpKeep - when we call the requestRandomWords in performUpKeep it calls fulfillRandomWords with the requestId and if the requestId is invalid it fails
      function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public raffleEnteredAndTimePassed skipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId/*1st request id*/, address(raffle));
        //this fulfillRandomWords can only be called by chainlink node
        //we need to check for multiple request ids
        //so we use a fuzz test by adding a uint256 randomRequestId parameter to the function
      }

      function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEnteredAndTimePassed skipFork {
        //the first player has already entered in the modifier
         uint256 startingBalance = PLAYER.balance;
        //ARRANGE
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(uint16(1));

        for(uint256 i=startingIndex; i<startingIndex + additionalEntrants; i++){
            address player = address(uint160(i));  //cool way of converting index to address
            hoax(player, 2 ether); //hoax is prank + deal
            raffle.enterRaffle{value: entranceFee}(); 
        }
        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        //through this we generate request id
        vm.recordLogs(); //record all the logs that happen during this transaction
        raffle.performUpkeep(""); 
        Vm.Log[] memory entries = vm.getRecordedLogs(); //get all the logs that happened during the last transaction
        bytes32 requestId = entries[1].topics[1]; //the second log is the one we want, and the first topic is the requestId
       
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle)); //we need to convert bytes32 to uint256 
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalEntrants + 1); //+1 is for the original player
        uint256 winnerBalance = recentWinner.balance();

        assert(recentWinner == expectedWinner);
        assert(raffleState == Raffle.RaffleState.OPEN);
        assert(endingTimeStamp > startingTimeStamp);
        assert(winnerBalance == STARTING_PLAYER_BALANCE + prize); // checking if the winner got the prize money
        assert(raffle.getNumberOfPlayers() == 0);  
        // AT THIS POINT WE GET AN INSUFFIECIENT BALANCE ERROR BECAUSE
        // WE ARE TRYING TO SEND 0.04 ETHER TO AN ADDRESS THAT HAS 0 ETHER
        // THIS IS BECAUSE THE RAFFLE CONTRACT HAS 0 ETHER
        // WE NEED TO FUND THE RAFFLE CONTRACT WITH SOME ETHER
        // WE CAN DO THIS BY SENDING ETHER TO THE RAFFLE CONTRACT
        // IN THE BEFORE EACH FUNCTION
      
      }




}