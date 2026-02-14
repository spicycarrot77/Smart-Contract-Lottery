// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "tests/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
//importing the helper config contract to get the parameters for the raffle contract

contract CreateSubscription is Script {
    
    function createSubscriptionUsingConfig(address vrfCoordinator) public returns (uint256, address) {
        HelperConfig helperconfig = new HelperConfig();
        address vrfCoordinator = HelperConfig.getConfig().vrfCoordinator;
        address account = HelperConfig.getConfig().account;
        return createSubscription(vrfCoordinator, account);
        (uint256 subId,) = createSubscription(vrfCoordinator);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account) public returns (uint256, address) {
       console.log("Creating subscription on chain ID:", block.chainid );
       vm.startBroadcast(account);
       uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
       vm.stopBroadcast();
       console.log("Your subscription ID is:", subId);
       return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}


ontract FundSubscription is Script,CodeConstants {

    uint256 public constant FUND_AMOUNT = 3 ether;
    // This is the amount we will fund the subscription with
    // This contract is used to fund the subscription for the Raffle contract
    // It is a simple contract that funds the subscription with the given amount

    function fundSubscriptionUsingConfig(address vrfCoordinator, uint256 subscriptionId) public {
        HelperConfig helperconfig = new HelperConfig();
        address vrfCoordinator = HelperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = HelperConfig.getConfig().subscriptionId;
        address linkToken = HelperConfig.getConfig().link;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);   
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        console.log("Funding subscription on chain ID:", block.chainid );
        if(block.chainid == LOCAL_CHAIN_ID){  
        vm.startBroadcast();
        // we need the link token address to fund the subscription
        // we can get this from the helper config contract
        // we also need the subscription ID to fund the subscription
        // we can get this from the helper config contract
        VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 1000);
        vm.stopBroadcast();
        }
        else{
            console.log("Funding subscription on live network");
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
        console.log("Funded subscription with %s LINK", FUND_AMOUNT / 1e18);
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    // This contract is used to add a consumer to the subscription for the Raffle contract
    // It is a simple contract that adds the consumer to the subscription with the given parameters

    function addConsumerUsingConfig(address mostrecentDeployedContract) public {
        HelperConfig helperconfig = new HelperConfig();
        address vrfCoordinator = HelperConfig.getConfig().vrfCoordinator;
        uint256 subId = HelperConfig.getConfig().subscriptionId;
        address consumer = address(0); // replace with your contract address
        addConsumer(vrfCoordinator, subscriptionId,mostrecentDeployedContract);
    }

    function addConsumer(address vrfCoordinator, uint256 subId, address contractToAddtoVRF) public {
        console.log("Adding consumer on chain ID:", block.chainid );
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddtoVRF);
        vm.stopBroadcast();
        console.log("Added consumer:", consumer);
    }

    function run() public {
        address mostrecentDeployedContract = DevOpsTools.get_most_recent_deployment("Raffle",
            block.chainid);
        addConsumerUsingConfig(mostrecentDeployedContract);
    }
}