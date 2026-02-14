// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

//the variables in the constuctor of raffle contract depend on the chain on which the contract is deployed especially the address of the vrfcoordinator therfore we need helperconfig

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "@chainlink/contracts/src/v0.8/mocks/LinkToken.sol";
//mock contract for local testing of VRFv2.5


abstract contract CodeConstants {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 1115511;
    uint256 public constant LOCAL_CHAIN_ID = 31337;  
    uint96 public constant MOCK_BASE_FEE = 0.25 ether; // 0.1 LINK
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9; // 0.000000001 LINK per gas
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;      
}

contract HelperConfig is CodeConstants,Script {
    // This contract is used to store the configuration for the Raffle contract
    // It is a simple contract that stores the parameters for the Raffle contract

    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint256 entranceFee;
        uint256 interval;
        uint256 callbackGasLimit;
        address link;
        address account;
    }

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        // Initialize the local network configuration
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
}

     function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (networkConfigs[chainId].vrfCoordinator != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilConfig();
        } else {
            revert("No configuration for this chain ID");
        }

     function getConfig() public returns (NetworkConfig memory){
        return getConfigByChainId(block.chainid);
        //this is a helper function which gets called in the deploy script
    }


     function getSepoliaEthConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return NetworkConfig({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            interval: 30, // 30 seconds
            entranceFee: 0.01 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2_5: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            account: 0x643315C9Be056cDEA171F4e7b2222a4ddaB9F88D
        });
    }

    function getOrCreateAnvilConfig()
        public
        returns (NetworkConfig memory)
    {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        // 1. Deploy t he mocks- we want to test it with mock vrfcoordinator contract
        // 2. Create a subscription
        // 3. Fund the subscription
        vm.startBroadcast();
        //deploying the mock vrfcoordinator contract
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE,MOCK_GAS_PRICE_LINK,MOCK_WEI_PER_UNIT_LINK
        );//whenever we work with chainlink we need to pay a certain amount of linktokens and basefee is the flat amount of tokens you have to pay and when the chainlink vrf call fulfill randomwords it has to pay gas and wei-per-unit-link is the per unit price of link in eth(wei)
        uint64 subscriptionId = vrfCoordinatorV2Mock.createSubscription();
        vrfCoordinatorV2Mock.fundSubscription(subscriptionId, 1 ether);
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            vrfCoordinator: address(vrfCoordinatorV2Mock),
            gasLane: 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15, // 200 gwei key hash
            subscriptionId: 0,
            entranceFee: 0.01 ether,
            interval: 30,
            callbackGasLimit: 500000,
            link: address(linkToken)
        });
        return localNetworkConfig;
    }
}