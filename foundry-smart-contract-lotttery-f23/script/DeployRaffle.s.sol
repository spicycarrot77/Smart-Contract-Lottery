// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;
   
import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/interactions.s.sol";
import {HelperConfig} from "./HelperConfig.s.sol";


contract DeployRaffle is Script{

    function run () public {
        deployContract();
    }
    // This contract is used to deploy the Raffle contract
    // It is a simple contract that deploys the Raffle contract with the given parameters

    function deployContract() external returns (Raffle, HelperConfig) {
        HelperConfig helperconfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperconfig.getConfig();
        //getConfig() returns a struct 

        if(config.subscriptionId == 0){
            // If we are deploying to a real network and subscriptionId is 0, we need to create one!
            // We will do this in a later lesson!
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) = 
                                   CreateSubscription.createSubscription(config.vrfCoordinator);
            // we have now created a subscription and now we'll fund it 
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);

        }


        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.subscriptionId,
            config.gasLane,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(config.vrfCoordinator, config.subscriptionId, address(raffle));

        return(raffle,helperconfig);
    }
}

